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
  end
end
