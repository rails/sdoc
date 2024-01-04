require "erb"

module SDoc::Helpers
  include ERB::Util

  require_relative "helpers/git"
  include SDoc::Helpers::Git

  LEADING_PARAGRAPH_XPATH =
    "./*[not(self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6)][1][self::p]"

  def link_to(text, url = nil, html_attributes = {})
    url, html_attributes = nil, url if url.is_a?(Hash)
    url ||= text

    text = _link_body(text)

    if url.is_a?(RDoc::CodeObject)
      url = "/#{url.path}"
      default_class = "ref-link" if text.start_with?("<code>") && text.end_with?("</code>")
    end

    html_attributes = html_attributes.transform_keys(&:to_s)
    html_attributes = { "href" => url, "class" => default_class }.compact.merge(html_attributes)

    attribute_string = html_attributes.map { |name, value| %( #{name}="#{h value}") }.join
    %(<a#{attribute_string}>#{text}</a>)
  end

  def _link_body(text)
    text.is_a?(RDoc::CodeObject) ? full_name_for(text) : text
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

  def button_to_search(query, display_name: full_name_for(query))
    query = query.full_name if query.is_a?(RDoc::CodeObject)
    %(<button class="query-button" data-query="#{h query} ">Search #{display_name}</button>)
  end

  def full_name_for(named)
    named = named.full_name if named.is_a?(RDoc::CodeObject)
    "<code>#{named.split(%r"(?<=./|.::)").map { |part| h part }.join("<wbr>")}</code>"
  end

  def short_name_for(named)
    named = named.name if named.is_a?(RDoc::CodeObject)
    "<code>#{h named}</code>"
  end

  def description_for(rdoc_object)
    if rdoc_object.comment && !rdoc_object.comment.empty?
      %(<div class="description">#{rdoc_object.description}</div>)
    end
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

  def outline(context)
    comment = context.respond_to?(:comment_location) ? context.comment_location : context.comment
    return if comment.empty?

    headings = context.parse(comment).table_of_contents
    headings.shift if headings.one? { |heading| heading.level == 1 } && headings[0].level == 1

    _outline_list(context, headings)
  end

  def _outline_list(context, headings, following: 0)
    items = []
    while headings[0] && headings[0].level > following
      items << _outline_list_item(context, headings)
    end
    "<ul>#{items.join}</ul>" unless items.empty?
  end

  def _outline_list_item(context, headings)
    heading = headings.shift
    link = link_to(heading.plain_html, "##{heading.label(context)}")
    sublist = _outline_list(context, headings, following: heading.level)
    "<li>#{link}#{sublist}</li>"
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

  def top_modules(rdoc_store)
    _top_modules(rdoc_store).reject { |rdoc_module| _core_ext?(rdoc_module) }
  end

  def core_extensions(rdoc_store)
    _top_modules(rdoc_store).select { |rdoc_module| _core_ext?(rdoc_module) }
  end

  def _top_modules(rdoc_store)
    rdoc_store.all_classes_and_modules.select do |rdoc_module|
      !rdoc_module.full_name.include?("::")
    end.sort
  end

  def _core_ext?(rdoc_module)
    # HACK There is currently a bug in RDoc v6.5.0 that causes the value of
    # RDoc::ClassModule#in_files for `Object` to become polluted. The cause is
    # unclear, but it might be related to setting global constants (for example,
    # setting `APP_PATH = "..."` outside of a class or module). To work around
    # this bug, we always treat `Object` as a core extension.
    rdoc_module.full_name == "Object" ||

    rdoc_module.in_files.all? { |rdoc_file| @options.core_ext_pattern.match?(rdoc_file.full_name) }
  end

  def module_breadcrumbs(rdoc_module)
    parent_names = rdoc_module.full_name.split("::")[0...-1]

    crumbs = parent_names.each_with_index.map do |name, i|
      parent = rdoc_module.store.find_class_or_module(parent_names[0..i].join("::"))
      parent ? link_to(h(name), parent) : h(name)
    end

    "<code>#{[*crumbs, h(rdoc_module.name)].join("::<wbr>")}</code>"
  end

  def module_ancestors(rdoc_module)
    ancestors = rdoc_module.includes.map { |inc| ["module", inc.module] }

    if !rdoc_module.module? && superclass = rdoc_module.superclass
      superclass_name = superclass.is_a?(String) ? superclass : superclass.full_name
      ancestors.unshift(["class", superclass]) unless superclass_name == "Object"
    end

    ancestors
  end

  def module_methods(rdoc_module)
    rdoc_module.each_method.sort_by do |rdoc_method|
      [rdoc_method.singleton ? 0 : 1, rdoc_method.name]
    end
  end

  def method_signature(rdoc_method)
    signature = if rdoc_method.call_seq
      # Support specifying a call-seq like `to_s -> string`
      rdoc_method.call_seq.gsub(/^\s*([^(\s]+)(.*?)(?: -> (.+))?$/) do
        "<b>#{h $1}</b>#{h $2}#{" <span class=\"returns\">&rarr;</span> #{h $3}" if $3}"
      end
    else
      "<b>#{h rdoc_method.name}</b>#{h rdoc_method.params}"
    end

    "<code>#{signature}</code>"
  end

  def method_source_code_and_url(rdoc_method)
    source_code = rdoc_method.markup_code if rdoc_method.token_stream

    if source_code&.match(/File\s(\S+), line (\d+)/)
      source_url = github_url($1, line: $2)
    end

    [(source_code unless rdoc_method.instance_of?(RDoc::GhostMethod)), source_url]
  end
end
