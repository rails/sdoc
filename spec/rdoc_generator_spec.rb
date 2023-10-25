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

  it "generates a search index" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        rdoc_run("--files", "#{__dir__}/../README.md", "#{__dir__}/../lib/sdoc/version.rb")
        index = File.read("doc/js/search-index.js")
        index.delete_prefix!("export default ").delete_suffix!(";")
        index.gsub!(/\(new Uint8Array\((.+?)\)\)/, '\1')
        _(JSON.parse(index).keys.sort).must_equal ["ngrams", "weights", "entries"].sort
      end
    end
  end

  describe "options.dry_run" do
    it "prevents files from being rendered" do
      Dir.mktmpdir do |dir|
        rdoc_dry_run(
          "--files", "#{__dir__}/../README.md", "#{__dir__}/../lib/sdoc/version.rb",
          "--output", dir
        )

        _(Dir.glob("**/*", base: dir)).must_be_empty
      end
    end
  end

  describe "options.core_ext_pattern" do
    it "is /core_ext/ by default" do
      _(parse_options().core_ext_pattern).must_equal %r"core_ext"
    end

    it "can be set via --core-ext" do
      _(parse_options("--core-ext", "foo.*bar").core_ext_pattern).must_equal %r"foo.*bar"
    end
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

  describe "#index" do
    before do
      @dir = File.expand_path("../lib", __dir__)
      @files = ["sdoc.rb", "sdoc/version.rb"].sort.reverse
    end

    it "defaults to the first --files value" do
      Dir.chdir(@dir) do
        sdoc = rdoc_dry_run("--files", *@files).generator
        _(sdoc.index.absolute_name).must_equal @files.first
      end
    end

    it "raises when the default value is not a file" do
      error = _{ rdoc_dry_run("--files", @dir, "--exclude=(js|css|svg)$") }.must_raise
      _(error.message).must_include @dir
    end

    it "uses the value of --main" do
      Dir.chdir(@dir) do
        sdoc = rdoc_dry_run("--main", @files.first, "--files", *@files).generator
        _(sdoc.index.absolute_name).must_equal @files.first
      end
    end

    it "raises when the main page is not among the rendered files" do
      Dir.chdir(@dir) do
        error = _{ rdoc_dry_run("--main", @files.first, "--files", @files.last) }.must_raise
        _(error.message).must_include @files.first
      end
    end

    it "works when --root is specified" do
      Dir.chdir(File.dirname(@dir)) do
        root = File.basename(@dir)
        @files.map! { |file| File.join(root, file) }
        sdoc = rdoc_dry_run("--root", root, "--main", @files.first, "--files", *@files).generator
        _(sdoc.index.absolute_name).must_equal @files.first
      end
    end

    it "works with unresolved paths" do
      Dir.chdir(@dir) do
        @files.map! { |file| File.join("..", File.basename(@dir), ".", file) }
        sdoc = rdoc_dry_run("--main", @files.first, "--files", *@files).generator
        _(sdoc.index.absolute_name).must_equal @files.first
      end
    end

    it "works with absolute paths" do
      @files.map! { |file| File.join(@dir, file) }
      sdoc = rdoc_dry_run("--main", @files.first, "--files", *@files).generator
      _(sdoc.index.absolute_name).must_equal @files.first
    end

    it "overrides RDoc::TopLevel#path" do
      Dir.chdir(@dir) do
        sdoc = rdoc_dry_run("--files", *@files).generator
        _(sdoc.index.path).must_equal ""
        sdoc.store.all_files.each { |file| _(file.path).wont_equal "" }
      end
    end
  end
end
