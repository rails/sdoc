require File.join(File.dirname(__FILE__), '/spec_helper')

describe RDoc::Generator::SDoc do
  def parse_options(*options)
    rdoc_options = nil

    _stdout, stderr = capture_io do
      rdoc_options = RDoc::Options.new.parse(["--format=sdoc", *options.flatten])
    end

    assert_empty stderr

    rdoc_options
  end

  it "is registered in RDoc::RDoc::GENERATORS" do
    _(RDoc::RDoc::GENERATORS).must_include 'sdoc'
  end

  it "is activated via --format=sdoc" do
    options = parse_options()
    _(options.generator).must_equal RDoc::Generator::SDoc
    _(options.generator_name).must_equal "sdoc"
  end

  it "displays SDoc's version via --version" do
    _(`./bin/sdoc --version`.strip).must_equal SDoc::VERSION
  end

  it "displays SDoc's version via -v" do
    _(`./bin/sdoc -v`.strip).must_equal SDoc::VERSION
  end

  describe "options.github" do
    it "is disabled by default" do
      _(parse_options().github).must_be_nil
    end

    it "is enabled via --github" do
      _(parse_options("--github").github).must_equal true
    end

    it "is enabled via -g" do
      _(parse_options("-g").github).must_equal true
    end
  end
end
