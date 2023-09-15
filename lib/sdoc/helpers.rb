module SDoc::Helpers
  require_relative "helpers/git"
  include SDoc::Helpers::Git

  LEADING_PARAGRAPH_XPATH =
    "./*[not(self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6)][1][self::p]"

  def link_to(text, url = nil, html_attributes = {})
    url, html_attributes = nil, url if url.is_a?(Hash)
    url ||= text
    attribute_string = html_attributes.map { |name, value| %( #{name}="#{h value}") }.join

    %(<a href="#{_link_url url}"#{attribute_string}>#{_link_body text}</a>)
  end

  def _link_url(url)
    h(url.is_a?(RDoc::CodeObject) ? "/#{url.path}" : url)
  end

  def _link_body(text)
    text.is_a?(RDoc::CodeObject) ? full_name(text) : text
  end

  def link_to_if(condition, text, *args)
    condition ? link_to(text, *args) : _link_body(text)
  end

  def link_to_external(text, url, html_attributes = {})
    html_attributes = html_attributes.transform_keys(&:to_s)
    html_attributes = { "target" => "_blank", "class" => nil }.merge(html_attributes)
    html_attributes["class"] = [*html_attributes["class"], "external-link"].join(" ")

    link_to(text, url, html_attributes)
  end

  def full_name(named)
    named = named.full_name if named.is_a?(RDoc::CodeObject)
    "<code>#{named.split(%r"(?<=./|.::)").map { |part| h part }.join("<wbr>")}</code>"
  end

  def short_name(named)
    named = named.name if named.is_a?(RDoc::CodeObject)
    "<code>#{h named}</code>"
  end

  def base_tag_for_context(context)
    relative_root = "../" * context.path.count("/")
    %(<base href="./#{relative_root}" data-current-path="#{context.path}">)
  end

  def canonical_url(path = nil)
    path = path.path if path.is_a?(RDoc::Context)
    "#{ENV["HORO_CANONICAL_URL"]}/#{path&.delete_prefix("/")}" if ENV["HORO_CANONICAL_URL"]
  end

  def project_name
    h(ENV["HORO_PROJECT_NAME"]) if ENV["HORO_PROJECT_NAME"]
  end

  def project_version
    version = ENV["HORO_BADGE_VERSION"] || ENV["HORO_PROJECT_VERSION"]
    h version if version
  end

  def project_git_head
    h "#{git_head_branch}@#{git_head_sha1[0, 12]}" if git?
  end

  def page_title(title = nil)
    h [title, @options.title].compact.join(" - ")
  end

  def og_title(title)
    project = [project_name, project_version].join(" ").strip
    "#{h title}#{" (#{project})" unless project.empty?}"
  end

  def og_modified_time
    git_head_timestamp
  end

  def page_description(leading_html, max_length: 160)
    return if leading_html.nil? || !leading_html.include?("</p>")

    text = Nokogiri::HTML.fragment(leading_html).at(LEADING_PARAGRAPH_XPATH)&.inner_text
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

  def more_less_ul(items, limit)
    soft_limit, hard_limit = (limit.is_a?(Range) ? limit : [limit]).minmax
    items = items.map { |item| "<li>#{item}</li>" }

    if items.length > hard_limit
      <<~HTML
        <ul>#{items[0...soft_limit].join}</ul>
        <details class="more-less">
          <summary>
            <span class="more-less__more">#{items.length - soft_limit} More</span>
            <span class="more-less__less">Less</span>
          </summary>
          <ul>#{items[soft_limit..].join}</ul>
        </details>
      HTML
    else
      "<ul>#{items.join}</ul>"
    end
  end

  def module_breadcrumbs(rdoc_module)
    crumbs = [h(rdoc_module.name)]

    rdoc_module.each_parent do |parent|
      break if parent.is_a?(RDoc::TopLevel)
      crumbs.unshift(link_to(h(parent.name), parent))
    end

    "<code>#{crumbs.join("::<wbr>")}</code>"
  end

  def module_ancestors(rdoc_module)
    ancestors = rdoc_module.includes.map { |inc| ["module", inc.module] }

    if !rdoc_module.module? && superclass = rdoc_module.superclass
      superclass_name = superclass.is_a?(String) ? superclass : superclass.full_name
      ancestors.unshift(["class", superclass]) unless superclass_name == "Object"
    end

    ancestors
  end

  def method_signature(rdoc_method)
    if rdoc_method.call_seq
      rdoc_method.call_seq.split(/\n+/).map do |line|
        # Support specifying a call-seq like `to_s -> string`
        line.split(" -> ").map { |side| "<code>#{h side}</code>" }.join(" &rarr; ")
      end.join("\n")
    else
      %Q(<code><span class="method__name">#{h rdoc_method.name}</span>#{h rdoc_method.params}</code>)
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
