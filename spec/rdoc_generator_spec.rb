require File.join(File.dirname(__FILE__), '/spec_helper')

describe RDoc::Generator::SDoc do
  before :each do
    @options = RDoc::Options.new
    @options.setup_generator 'sdoc'
    @parser = @options.option_parser
  end

  it "should find sdoc generator" do
    _(RDoc::RDoc::GENERATORS).must_include 'sdoc'
  end

  it "should use sdoc generator" do
    _(@options.generator).must_equal RDoc::Generator::SDoc
    _(@options.generator_name).must_equal 'sdoc'
  end

  it "should parse github option" do
    assert !@options.github

    _, err = capture_io do
      @parser.parse %w[--github]
    end

    _(err).wont_match(/^invalid options/)
    _(@options.github).must_equal true
  end

  it "should parse github short-hand option" do
    assert !@options.github

    _, err = capture_io do
      @parser.parse %w[-g]
    end

    _(err).wont_match(/^invalid options/)
    _(@options.github).must_equal true
  end

  it "should display SDoc version on -v or --version" do
    out_full  = `./bin/sdoc --version`
    out_short = `./bin/sdoc -v`

    _(out_short.strip).must_equal SDoc::VERSION
    _(out_full.strip).must_equal SDoc::VERSION
  end
end
