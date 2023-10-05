require "spec_helper"

describe SDoc::Renderer do
  before do
    @template_dir = Dir.mktmpdir
    @rdoc_options = RDoc::Options.new.tap do |options|
      options.template_dir = @template_dir
    end
  end

  after do
    FileUtils.remove_entry(@template_dir)
  end

  def create_template(name, erb)
    File.write(File.join(@template_dir, name), erb)
  end

  describe "#render" do
    it "renders an ERB template" do
      create_template "foo.erb", %(<%= "foo".upcase %>)

      _(SDoc::Renderer.new(nil, @rdoc_options).render("foo.erb")).
        must_equal "FOO"
    end

    it "supports local variables" do
      create_template "foo.erb", %(<%= foo.upcase %>)

      _(SDoc::Renderer.new(nil, @rdoc_options).render("foo.erb", { foo: "bar" })).
        must_equal "BAR"
    end

    it "provides access to @context" do
      create_template "foo.erb", %(<%= @context[:foo] %>)

      _(SDoc::Renderer.new({ foo: "bar" }, @rdoc_options).render("foo.erb")).
        must_equal "bar"
    end

    it "provides access to @options" do
      create_template "foo.erb", %(<%= @options.object_id %>)

      _(SDoc::Renderer.new(nil, @rdoc_options).render("foo.erb")).
        must_equal @rdoc_options.object_id.to_s
    end

    it "provides access to helper methods" do
      create_template "foo.erb", %(<%= h "foo & bar" %>)

      _(SDoc::Renderer.new(nil, @rdoc_options).render("foo.erb")).
        must_equal "foo &amp; bar"
    end

    it "is reentrant" do
      create_template "foo.erb", %(1 + 1 = <%= render "two.erb" %>)
      create_template "two.erb", %(<%= 1 + 1 %>)

      _(SDoc::Renderer.new(nil, @rdoc_options).render("foo.erb")).
        must_equal "1 + 1 = 2"
    end
  end

  describe "#inline" do
    it "supports isolated local variables" do
      create_template "outer.erb", %(<%= foo %> <% inline "inner.erb", bar: "BAR" %> <%= foo %>)
      create_template "inner.erb", %(<%= foo = bar %>)

      _(SDoc::Renderer.new(nil, @rdoc_options).render("outer.erb", { foo: "FOO" })).
        must_equal "FOO BAR FOO"
    end

    it "provides access to the same non-local values as #render" do
      create_template "outer.erb", %(<% inline "inner.erb" %>)
      create_template "inner.erb", %(<%= h @context[:foobar] %>)

      _(SDoc::Renderer.new({ foobar: "foo & bar" }, @rdoc_options).render("outer.erb")).
        must_equal "foo &amp; bar"
    end

    it "supports yield" do
      create_template "outer.erb", '1 <% inline("inner.erb") { 3 } %> 5'
      create_template "inner.erb", %(2 <%= yield %> 4)

      _(SDoc::Renderer.new(nil, @rdoc_options).render("outer.erb")).
        must_equal "1 2 3 4 5"
    end

    it "supports interleaved rendering" do
      create_template "outer.erb", '1 <% inline("inner.erb") do %>3<% end %> 5'
      create_template "inner.erb", %(2 <% yield %> 4)

      _(SDoc::Renderer.new(nil, @rdoc_options).render("outer.erb")).
        must_equal "1 2 3 4 5"
    end

    it "supports interleaved rendering with nested #inline calls" do
      create_template "outer.erb", '1 <% inline("middle.erb") { inline("inner.erb") } %> 5'
      create_template "middle.erb", %(2 <% yield %> 4)
      create_template "inner.erb", %(3)

      _(SDoc::Renderer.new(nil, @rdoc_options).render("outer.erb")).
        must_equal "1 2 3 4 5"
    end
  end
end
