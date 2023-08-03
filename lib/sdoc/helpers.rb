module SDoc::Helpers
  require_relative "helpers/git"
  include SDoc::Helpers::Git

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
    relative_root = "../" * context.path.count("/") if context
    %(<base href="./#{relative_root}" data-current-path="#{context&.path}">)
  end

  def canonical_url(path = nil)
    path = path.path if path.is_a?(RDoc::Context)
    "#{ENV["HORO_CANONICAL_URL"]}/#{path&.delete_prefix("/")}" if ENV["HORO_CANONICAL_URL"]
  end

  def project_name
    h(ENV["HORO_PROJECT_NAME"]) if ENV["HORO_PROJECT_NAME"]
  end

  def project_version
    h(ENV["HORO_PROJECT_VERSION"]) if ENV["HORO_PROJECT_VERSION"]
  end

  def badge_version
    h(ENV["HORO_BADGE_VERSION"]) if ENV["HORO_BADGE_VERSION"]
  end

  def page_title(title = nil)
    h [title, @options.title].compact.join(" - ")
  end

  def og_title(title)
    project = [project_name, badge_version].join(" ").strip
    "#{h title}#{" (#{project})" unless project.empty?}"
  end

  def og_modified_time
    git_head_timestamp
  end

  def page_description(leading_html, max_length: 160)
    return if leading_html.nil? || !leading_html.include?("</p>")

    text = Nokogiri::HTML.fragment(leading_html).at_css("h1 + p, p:first-child")&.inner_text
    return unless text

    if text.length > max_length
      # `+ 1 - 3` because we remove at least one character and replace it with "...".
      text = text[0, max_length + 1 - 3].sub(/(?:\W+|\W*\w+)\Z/, "...")
    end

    h text
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
