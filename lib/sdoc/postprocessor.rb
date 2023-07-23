require "nokogiri"
require "pathname"
require "rouge"

module SDoc::Postprocessor
  extend self

  def process(rendered)
    document = Nokogiri::HTML.parse(rendered)

    adjust_urls!(document)
    highlight_code_blocks!(document)

    document.to_s
  end

  TAG_ATTRIBUTES_AFFECTED_BY_BASE_TAG = {
    link: :href,
    script: :src,
    a: :href,
    img: :src,
  }

  def adjust_urls!(document)
    current_path = document.at_css("base")&.attr("data-current-path")
    return unless current_path

    TAG_ATTRIBUTES_AFFECTED_BY_BASE_TAG.each do |tag, attr|
      document.css("#{tag}[#{attr}]").each do |element|
        element[attr] = adjust_url(element[attr], current_path)
      end
    end
  end

  def adjust_url(url, current_path)
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

  def highlight_code_blocks!(document)
    document.css(".description pre > code, .sourcecode pre > code").each do |element|
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
    when /^ *<[%a-z]/i
      "erb" # also highlights HTML
    else
      "ruby"
    end
  end
end
