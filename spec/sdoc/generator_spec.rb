require File.join(File.dirname(__FILE__), '/../spec_helper')

describe RDoc::Generator::SDoc do
  before :each do
    @options = RDoc::Options.new
    @options.setup_generator 'sdoc'
    @parser = @options.option_parser
  end

  it "should find sdoc generator" do
    RDoc::RDoc::GENERATORS.must_include 'sdoc'
  end

  it "should use sdoc generator" do
    @options.generator.must_equal RDoc::Generator::SDoc
    @options.generator_name.must_equal 'sdoc'
  end

  it "should parse github option" do
    out, err = capture_io do
      @parser.parse '--github'
    end

    err.wont_match /^invalid options/
    @options.github.must_equal true
  end

  it "should parse github short-hand option" do
    out, err = capture_io do
      @parser.parse '-g'
    end

    err.wont_match /^invalid options/
    @options.github.must_equal true
  end

  it "should parse no search engine index option" do
    out, err = capture_io do
      @parser.parse '--no-se-index'
    end

    err.wont_match /^invalid options/
    @options.se_index.must_equal false
  end

  it "should parse no-se-index shorthand option" do
    out, err = capture_io do
      @parser.parse '-ns'
    end

    err.wont_match /^invalid options/
    @options.se_index.must_equal false
  end

end
