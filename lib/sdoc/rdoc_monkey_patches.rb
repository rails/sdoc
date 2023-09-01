require "rdoc"

RDoc::TopLevel.prepend(Module.new do
  attr_writer :path

  def path
    @path ||= super
  end
end)


RDoc::Markup::ToHtmlCrossref.prepend(Module.new do
  def cross_reference(name, text = nil, code = true)
    if text
      # Style ref links that look like code, such as `{Rails}[rdoc-ref:Rails]`.
      code ||= !text.include?(" ") || text.match?(/\S\(/)
    elsif name.match?(/\A[A-Z](?:[A-Z]+|[a-z]+)\z/)
      # Prevent unintentional ref links, such as `Rails` or `ERB`.
      return name
    end

    super
  end
end)
