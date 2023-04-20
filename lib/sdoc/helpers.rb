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

  def horo_canonical_url(canonical_url, context)
    if context == :index
      return "#{canonical_url}/"
    end

    return "#{canonical_url}/#{context.as_href("")}"
  end

  def github_link(markup)
    if markup =~ /File\s(\S+), line (\d+)/
      path = $1
      line = $2.to_i
    end
    path && github_url(path)
  end

  def source_link(source_id, github, ghost)
    link = ""

    unless ghost
      link << "<a href=\"javascript:toggleSource('#{source_id}')\" id=\"l_#{source_id}\">show</a>"
    end

    link << " | " if !ghost && github

    if github
      github_link_url = "#{github}#L#{line}"
      link << "<a href=\"#{github_link_url}\" target=\"_blank\" class=\"github_url\">on GitHub</a>"
    end
    link
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
