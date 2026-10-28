module SDoc::Helpers
  def each_letter_group(methods, &block)
    group = {:name => '', :methods => []}
    methods.sort{ |a, b| a.name <=> b.name }.each do |method|
      gname = group_name method.name
      if gname != group[:name]
        yield group unless group[:methods].size == 0
        group = {
          :name => gname,
          :methods => []
        }
      end
      group[:methods].push(method)
    end
    yield group unless group[:methods].size == 0
  end

  # Strips out HTML tags from a given string.
  #
  # Example:
  #
  #   strip_tags("<strong>Hello world</strong>") => "Hello world"
  def strip_tags(text)
    text.gsub(%r{</?[^>]+?>}, "")
  end

  # Truncates a given string. It tries to take whole sentences to have
  # a meaningful description for SEO tags.
  #
  # The only available option is +:length+ which defaults to 200.
  def truncate(text, options = {})
    if text
      length = options.fetch(:length, 200)
      stop   = text.rindex(".", length - 1) || length

      "#{text[0, stop]}."
    end
  end

  # Returns the RBS type signature of a method or attribute as HTML, with
  # type names linked to their documentation, or +nil+ when it has none.
  #
  # Type signatures come from inline <tt>#:</tt> annotations or from RBS
  # files, and require RDoc >= 8.0.
  def type_signature_html(method_attr, from_path)
    return unless defined?(RDoc::RbsHelper) && method_attr.respond_to?(:type_signature_lines)

    lines = method_attr.type_signature_lines || @store.rbs_signature_for(method_attr)
    return unless lines

    RDoc::RbsHelper.signature_to_html(lines, lookup: @store.type_name_lookup, from_path: from_path)
  end

protected
  def group_name name
    if match = name.match(/^([a-z])/i)
      match[1].upcase
    else
      '#'
    end
  end
end
