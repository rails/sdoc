require "nokogiri"
require_relative "helpers"

module SDoc::SearchIndex
  extend self

  class Uint8Array < Array
    # This doesn't generate valid JSON, but it is suitable as an export from an
    # ES6 module.
    def to_json(*)
      "(new Uint8Array(#{super}))"
    end
  end

  def generate(rdoc_modules)
    # RDoc duplicates RDoc::MethodAttr instances when modules are aliased by
    # assigning to a constant. For example, `MyBar = Foo::Bar` will duplicate
    # all of Foo::Bar's RDoc::MethodAttr instances.
    rdoc_objects = rdoc_modules + rdoc_modules.flat_map(&:method_list).uniq

    ngram_sets = rdoc_objects.map { |rdoc_object| derive_ngrams(rdoc_object.full_name) }
    ngram_bit_positions = compile_ngrams(ngram_sets)
    bit_weights = compute_bit_weights(ngram_bit_positions)

    entries = rdoc_objects.zip(ngram_sets).map do |rdoc_object, ngrams|
      rdoc_module, rdoc_method = rdoc_object.is_a?(RDoc::ClassModule) ? [rdoc_object] : [rdoc_object.parent, rdoc_object]
      description = rdoc_object.description

      [
        generate_fingerprint(ngrams, ngram_bit_positions),
        compute_tiebreaker_bonus(rdoc_module.full_name, rdoc_method&.name, description),
        rdoc_object.path,
        rdoc_module.full_name,
        (signature_for(rdoc_method) if rdoc_method),
        *truncate_description(description, 130),
      ]
    end

    { "ngrams" => ngram_bit_positions, "weights" => bit_weights, "entries" => entries }
  end

  def derive_ngrams(name)
    if name.match?(/:[^:A-Z]|#/)
      # Example: "ActiveModel::Name::new" => ["ActiveModel", "Name", ":new"]
      # Example: "ActiveModel::Name#<=>" => ["ActiveModel", "Name", "#<=>"]
      strings = name.split(/::(?=[A-Z])|:(?=:)|(?=#)/)

      # Example: ":lookup_store" => ".lookup_store("
      strings.concat(strings.map { |string| string.sub(/^[:#](.+)/, '.\1(') })
    else
      # Example: "ActiveSupport::Cache::Store" => [":ActiveSupport", ":Cache, ":Store"]
      strings = ":#{name}".split(/:(?=:)/)
    end

    # Example: ":API" => ":api"
    strings.concat(strings.map(&:downcase))
    # Example: ":HashWithIndifferentAccess" => ":HWIA"
    strings.concat(strings.map { |string| string.gsub(/([A-Z])[a-z]+/, '\1') })
    # Example: "#find_by_sql" => "#findbysql"
    strings.concat(strings.map { |string| string.tr("_", "") })
    # Example: "#action_name" => " action_name"
    strings.concat(strings.map { |string| string.tr(":#", " ") })
    # Example: " action_name" => " a "
    strings.concat(strings.map { |string| string.sub(/^([:# ].).+/, '\1 ') })

    strings.flat_map { |string| string.each_char.each_cons(3).map(&:join) }.uniq
  end

  def compile_ngrams(ngram_sets)
    # Assign each ngram a bit position based on its rarity. More common ngrams
    # come first. This reduces the average number of bytes required to store a
    # fingerprint.
    ngram_sets.flatten.tally.sort_by(&:last).reverse.map(&:first).each_with_index.to_h
  end

  def generate_fingerprint(ngrams, ngram_bit_positions)
    bit_positions = ngrams.map(&ngram_bit_positions)
    byte_count = ((bit_positions.max + 1) / 8.0).ceil
    bytes = [0] * byte_count

    bit_positions.each do |position|
      bytes[position / 8] |= 1 << (position % 8)
    end

    Uint8Array.new(bytes)
  end

  NGRAM_PATTERN_WEIGHTS = {
    /[^a-z]/ => 2, # Bonus point for non-lowercase-alpha chars because they show intentionality.
    /^ / => 3, # More points for matching generic start of token.
    /^:/ => 4, # Even more points for explicit start of token.
    /[#.(]/ => 50, # Strongly prefer methods when query includes "#", ".", or "(".
  }

  def compute_bit_weights(ngram_bit_positions)
    weights = ngram_bit_positions.uniq(&:last).sort_by(&:last).map do |ngram, _position|
      NGRAM_PATTERN_WEIGHTS.map { |pattern, weight| ngram.match?(pattern) ? weight : 1 }.max
    end

    Uint8Array.new(weights)
  end

  def compute_tiebreaker_bonus(module_name, method_name, description)
    # Give bonus in proportion to documentation length, but scale up extremely
    # slowly. Bonus is per matching ngram so it must be small enough to not
    # outweigh points from other matches.
    bonus = (description.length + 1) ** 0.01 / 100
    # Reduce bonus in proportion to name length. This favors short names over
    # long names. Notably, this will often favor methods over modules since
    # method names are usually shorter than fully qualified module names.
    bonus /= (method_name&.length || module_name.length) ** 0.1
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
