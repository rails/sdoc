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

  def link_to(text, url, html_attributes = {})
    return h(text) if url.nil?

    url = "/#{url.path}" if url.is_a?(RDoc::CodeObject)
    attribute_string = html_attributes.map { |name, value| %( #{name}="#{h value}") }.join

    %(<a href="#{h url}"#{attribute_string}>#{h text}</a>)
  end

  def base_tag_for_context(context)
    if context == :index
      %(<base href="./" data-current-path=".">)
    else
      relative_root = "../" * context.path.count("/")
      %(<base href="#{relative_root}" data-current-path="#{context.path}">)
    end
  end

  def canonical_url(context)
    if ENV["HORO_CANONICAL_URL"]
      if context == :index
        "#{ENV["HORO_CANONICAL_URL"]}/"
      else
        "#{ENV["HORO_CANONICAL_URL"]}/#{context.as_href("")}"
      end
    end
  end

  def project_name
    @html_safe_project_name ||= h(ENV["HORO_PROJECT_NAME"]) if ENV["HORO_PROJECT_NAME"]
  end

  def project_version
    @html_safe_project_version ||= h(ENV["HORO_PROJECT_VERSION"]) if ENV["HORO_PROJECT_VERSION"]
  end

  def badge_version
    @html_safe_badge_version ||= h(ENV["HORO_BADGE_VERSION"]) if ENV["HORO_BADGE_VERSION"]
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
