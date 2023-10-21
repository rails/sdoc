require "base64"
require "nokogiri"
require_relative "helpers"

module SDoc::SearchIndex
  extend self

  def generate(rdoc_modules)
    # RDoc duplicates RDoc::MethodAttr instances when modules are aliased by
    # assigning to a constant. For example, `MyBar = Foo::Bar` will duplicate
    # all of Foo::Bar's RDoc::MethodAttr instances.
    rdoc_objects = rdoc_modules + rdoc_modules.flat_map(&:method_list).uniq

    bigram_sets = rdoc_objects.map { |rdoc_object| derive_bigrams(rdoc_object.full_name) }
    bigram_bit_positions = compile_bigrams(bigram_sets)
    bit_weights = compute_bit_weights(bigram_bit_positions)

    entries = rdoc_objects.zip(bigram_sets).map do |rdoc_object, bigrams|
      rdoc_module, rdoc_method = rdoc_object.is_a?(RDoc::ClassModule) ? [rdoc_object] : [rdoc_object.parent, rdoc_object]
      description = rdoc_object.description

      [
        generate_fingerprint(bigrams, bigram_bit_positions),
        compute_tiebreaker_bonus(rdoc_module.full_name, rdoc_method&.name, description),
        rdoc_object.path,
        rdoc_module.full_name,
        (signature_for(rdoc_method) if rdoc_method),
        *truncate_description(description, 130),
      ]
    end

    { "bigrams" => bigram_bit_positions, "weights" => bit_weights, "entries" => entries }
  end

  def derive_bigrams(name)
    # Example: "ActiveSupport::Cache::Store" => ":ActiveSupport:Cache:Store"
    strings = [":#{name}".gsub("::", ":")]

    # Example: ":ActiveModel:API" => ":activemodel:api"
    strings.concat(strings.map(&:downcase))
    # Example: ":ActiveSupport:HashWithIndifferentAccess" => ":AS:HWIA"
    strings.concat(strings.map { |string| string.gsub(/([A-Z])[a-z]+/, '\1') })
    # Example: ":AbstractController:Base#action_name" => " AbstractController Base action_name"
    strings.concat(strings.map { |string| string.tr(":#", " ") })
    # Example: ":AbstractController:Base#action_name" => ":AbstractController:Base#actionname"
    strings.concat(strings.map { |string| string.tr("_", "") })

    # Example: ":ActiveModel:Name#<=>" => [":ActiveModel", ":Name", "#<=>"]
    strings.map! { |string| string.split(/(?=[ :#])/) }.flatten!

    if method_name_first_char = name[/(?:#|::)([^A-Z])/, 1]
      # Example: "AbstractController::Base::controller_path" => ".c"
      strings << ".#{method_name_first_char}"
      # Example: "AbstractController::Base::controller_path" => "h("
      strings << "#{name[-1]}("
    end

    strings.flat_map { |string| string.each_char.each_cons(2).map(&:join) }.uniq
  end

  def compile_bigrams(bigram_sets)
    # Assign each bigram a bit position based on its rarity. More common bigrams
    # come first. This reduces the average number of bytes required to store a
    # fingerprint.
    bigram_sets.flatten.tally.sort_by(&:last).reverse.map(&:first).each_with_index.to_h
  end

  def generate_fingerprint(bigrams, bigram_bit_positions)
    bit_positions = bigrams.map(&bigram_bit_positions)
    byte_count = ((bit_positions.max + 1) / 8.0).ceil
    bytes = [0] * byte_count

    bit_positions.each do |position|
      bytes[position / 8] |= 1 << (position % 8)
    end

    bytes
  end

  BIGRAM_PATTERN_WEIGHTS = {
    /[^a-z]/ => 2, # Bonus point for non-lowercase-alpha chars because they show intentionality.
    /^ / => 3, # More points for matching generic start of token.
    /^:/ => 4, # Even more points for explicit start of token.
    /[#.(]/ => 50, # Strongly prefer methods when query includes "#", ".", or "(".
  }

  def compute_bit_weights(bigram_bit_positions)
    bigram_bit_positions.uniq(&:last).sort_by(&:last).map do |bigram, _position|
      BIGRAM_PATTERN_WEIGHTS.map { |pattern, weight| bigram.match?(pattern) ? weight : 1 }.max
    end
  end

  def compute_tiebreaker_bonus(module_name, method_name, description)
    method_name ||= ""

    # Bonus is per matching bigram and is very small so it does not outweigh
    # points from other matches. Longer names have smaller per-bigram bonuses,
    # but the value scales down very slowly.
    bonus = 0.01 / (module_name.length + method_name.length) ** 0.025

    # Further reduce bonus in proportion to method name length. This prioritizes
    # modules before methods, and short methods of long modules before long
    # methods of short modules. For example, when searching for "find_by", this
    # prioritizes ActiveRecord::FinderMethods#find_by before
    # ActiveRecord::Querying#find_by_sql.
    #
    # However, slightly dampen the reduction in proportion to the length of the
    # method description. When method names are the same, this marginally favors
    # methods with more documentation over methods with less documentation. For
    # example, favoring ActionController::Rendering#render (which is thoroughly
    # documented) over ActionController::Renderer#render (which primarily refers
    # to other methods).
    bonus *= (0.99 + [description.length, 1000].min / 250_000.0) ** method_name.length
  end

  def signature_for(rdoc_method)
    sigil = rdoc_method.singleton ? "::" : "#"
    params = rdoc_method.call_seq ? "(...)" : rdoc_method.params
    "#{sigil}#{rdoc_method.name}#{params}"
  end

  def truncate_description(description, limit)
    return if description.empty?
    leading_paragraph = Nokogiri::HTML.fragment(description).at(SDoc::Helpers::LEADING_PARAGRAPH_XPATH)
    return unless leading_paragraph

    # Treat <code> elements as a whole when truncating
    content = leading_paragraph.xpath(".//text()").map do |node|
      node.parent.name == "code" ? "_" * node.content.length : node.content
    end.join

    if content.length > limit
      # `+ 1 - 3` because we remove at least one character and replace it with "...".
      remaining = content[0, limit + 1 - 3].sub(/(?:\W+|\W*\w+)\Z/, "").length

      leading_paragraph.traverse do |node|
        if remaining <= 0
          node.remove if node.children.empty?
        elsif node.text?
          remaining -= node.content.length
          node.content = node.content[0...remaining] if remaining < 0
        end
      end

      leading_paragraph.add_child("...")
    elsif content.end_with?(":")
      # Append ellipsis if paragraph refers to a subsequent block.
      leading_paragraph.add_child("...")
    end

    # Replace links with their inner HTML
    leading_paragraph.css("a").each { |a| a.replace(a.children) }

    leading_paragraph.inner_html
  end
end
