require "nokogiri"
require "pathname"
require "rouge"
require "uri"

module SDoc::Postprocessor
  extend self

  def process(rendered)
    document = Nokogiri::HTML5.parse(rendered)

    rebase_urls!(document)
    version_rubyonrails_urls!(document)
    add_ref_link_classes!(document)
    unify_h1_headings!(document)
    highlight_code_blocks!(document)

    document.to_s
  end

  TAG_ATTRIBUTES_AFFECTED_BY_BASE_TAG = {
    link: :href,
    script: :src,
    a: :href,
    img: :src,
  }

  def rebase_urls!(document)
    current_path = document.at_css("base")&.attr("data-current-path")
    return unless current_path

    TAG_ATTRIBUTES_AFFECTED_BY_BASE_TAG.each do |tag, attr|
      document.css("#{tag}[#{attr}]").each do |element|
        element[attr] = rebase_url(element[attr], current_path)
      end
    end
  end

  def rebase_url(url, current_path)
    case
    when url.start_with?("//", "https:", "http:", "javascript:", "data:")
      url
    when url.start_with?("/")
      url[1..]
    when url.start_with?("#")
      current_path + url
    else
      Pathname(current_path).dirname.join(url).cleanpath.to_s
    end
  end

  def version_rubyonrails_urls!(document)
    if ENV["HORO_PROJECT_NAME"] == "Ruby on Rails" && version = ENV["HORO_PROJECT_VERSION"]
      document.css(
        "a[href^='https://api.rubyonrails.org/']",
        "a[href^='https://guides.rubyonrails.org/']"
      ).each do |element|
        element["href"] = version_url(element["href"], version)
      end
    end
  end

  def version_url(url, version)
    uri = URI(url)

    unless uri.path.match?(%r"\A/v\d")
      if version.match?(/\Av?[.0-9]+\z/)
        uri.path = "/#{version.sub(/\Av?/, "v")}#{uri.path}"
      else
        uri.host = "edge#{uri.host}"
      end
    end

    uri.to_s
  end

  def add_ref_link_classes!(document)
    document.css(".description a code").each do |element|
      if element.parent.children.one?
        element.parent.add_class("ref-link")
      end
    end
  end

  def unify_h1_headings!(document)
    if h1 = document.at_css("#context > .description h1:first-child")
      if hgroup = document.at_css("#content > hgroup")
        h1.remove
        hgroup.add_child(%(<p>#{h1.inner_html}</p>))
      end
    end
  end

  def highlight_code_blocks!(document)
    document.css(".description pre > code, pre.source-code > code").each do |element|
      code = element.inner_text
      language = element.classes.include?("ruby") ? "ruby" : guess_code_language(code)
      element.inner_html = highlight_code(code, language)
      element.add_class("highlight").add_class(language)
    end
  end

  def highlight_code(code, language)
    lexer = Rouge::Lexer.find_fancy(language)
    Rouge::Formatters::HTML.format(lexer.lex(code))
  end

  def guess_code_language(code)
    case code
    when /^\$ /
      "console"
    when /--[+|]--/ # ASCII-art table
      "plaintext"
    when /(?:GET|POST|PUT|PATCH|DELETE|HEAD) +\// # routes listing or HTTP request
      "plaintext"
    when /\A(?:SELECT|INSERT|UPDATE|DELETE|CREATE|ALTER|DROP) /
      "sql"
    when /^(?:To|Cc|Bcc): .+@/
      "email"
    when /^(?:- )?\w+:(?:\n| [#&|>])/ # YAML dictionary or list of dictionaries
      if code.include?("<%")
        code.include?("<<:") ? "plaintext" : "erb"
      else
        "yaml"
      end
    when /^ *<[%a-z]|%>$|<\/\w+>$/i
      "erb" # also highlights HTML
    else
      "ruby"
    end
  end
end
