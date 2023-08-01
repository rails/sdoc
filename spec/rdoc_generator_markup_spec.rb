require File.join(File.dirname(__FILE__), '/spec_helper')

describe RDoc::Generator::Markup do
  before :each do
    @module = RDoc::NormalModule.new 'Example::SomeClass'
  end

  describe "#comment_title" do
    it "should parse the h1 title from the comment if present" do
      @module.comment = RDoc::Comment.new '= Some Title'
      _(@module.comment_title).must_equal 'Some Title'
    end

    it "should parse the markdown h1 title from the comment if present" do
      @module.comment = RDoc::Comment.new '# Markdown Title'
      _(@module.comment_title).must_equal 'Markdown Title'
    end

    it "should ignore lower level titles" do
      @module.comment = RDoc::Comment.new '== Some Title'
      _(@module.comment_title).must_equal nil
    end
  end

  describe "#title" do
    it "should parse the h1 title from the comment if present" do
      @module.comment = RDoc::Comment.new '= Some Title'
      _(@module.title).must_equal 'Some Title'
    end

    it "should fallback to the full_name" do
      @module.comment = RDoc::Comment.new 'Some comment without title'
      _(@module.title).must_equal "Example::SomeClass"
    end
  end
end
