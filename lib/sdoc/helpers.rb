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

protected
  def group_name name
    if match = name.match(/^([a-z])/i)
      match[1].upcase
    else
      '#'
    end
  end
end
