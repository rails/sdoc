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

  describe "options.title" do
    it "includes ENV['HORO_PROJECT_NAME'] and ENV['HORO_PROJECT_VERSION'] by default" do
      with_env("HORO_PROJECT_NAME" => "My Gem", "HORO_PROJECT_VERSION" => "v2.0") do
        _(parse_options().title).must_equal "My Gem v2.0 API documentation"
      end

      with_env("HORO_PROJECT_NAME" => "My Gem", "HORO_PROJECT_VERSION" => nil) do
        _(parse_options().title).must_equal "My Gem API documentation"
      end

      with_env("HORO_PROJECT_NAME" => nil, "HORO_PROJECT_VERSION" => "v2.0") do
        _(parse_options().title).must_equal "v2.0 API documentation"
      end

      with_env("HORO_PROJECT_NAME" => nil, "HORO_PROJECT_VERSION" => nil) do
        _(parse_options().title).must_equal "API documentation"
      end
    end

    it "prioritizes ENV['HORO_BADGE_VERSION'] over ENV['HORO_PROJECT_VERSION']" do
      with_env("HORO_BADGE_VERSION" => "badge", "HORO_PROJECT_VERSION" => "project") do
        _(parse_options().title).must_equal "badge API documentation"
      end
    end

    it "can be overridden" do
      _(parse_options("--title", "Docs Docs Docs!").title).must_equal "Docs Docs Docs!"
    end
  end
end
