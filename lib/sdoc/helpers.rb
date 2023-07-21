module SDoc::Helpers
  require_relative "helpers/github"
  include SDoc::Helpers::GitHub

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

  def link_to_external(text, url, html_attributes = {})
    html_attributes = html_attributes.transform_keys(&:to_s)
    html_attributes = { "target" => "_blank", "class" => nil }.merge(html_attributes)
    html_attributes["class"] = [*html_attributes["class"], "external-link"].join(" ")

    link_to(text, url, html_attributes)
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

  def group_by_first_letter(rdoc_objects)
    rdoc_objects.sort_by(&:name).group_by do |object|
      object.name[/^[a-z]/i]&.upcase || "#"
    end
  end

  def method_source_code_and_url(rdoc_method)
    source_code = rdoc_method.markup_code if rdoc_method.token_stream

    if source_code&.match(/File\s(\S+), line (\d+)/)
      source_url = github_url($1, line: $2)
    end

    [(source_code unless rdoc_method.instance_of?(RDoc::GhostMethod)), source_url]
  end
end
