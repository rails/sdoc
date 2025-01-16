require "rdoc"

RDoc::TopLevel.prepend(Module.new do
  attr_writer :path

  def path
    @path ||= super
  end
end)


RDoc::Constant.prepend(Module.new do
  def aref_prefix
    "constant"
  end

  def aref
    "#{aref_prefix}-#{name}"
  end

  def path
    "#{super.sub(/#.+/, "")}##{aref}"
  end
end)


RDoc::AnyMethod.prepend(Module.new do
  def params
    super&.sub(/\A\(\s+/, "(")&.sub(/\s+\)\z/, ")")
  end
end)


RDoc::Markup::ToHtmlCrossref.prepend(Module.new do
  def cross_reference(name, text = nil, code = true, *, **)
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


RDoc::Parser::Ruby.prepend(Module.new do
  def get_class_or_module(container, ignore_constants = false)
    @ignoring_constants ||= nil
    original_ignoring_constants, @ignoring_constants = @ignoring_constants, ignore_constants
    super
  ensure
    @ignoring_constants = original_ignoring_constants
  end

  def record_location(*)
    @ignoring_constants ||= nil
    super unless @ignoring_constants
  end
end)
