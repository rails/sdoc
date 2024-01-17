require "spec_helper"

describe SDoc::Helpers do
  before :each do
    @helpers = Class.new do
      include SDoc::Helpers

      attr_accessor :options
    end.new

    @helpers._git.clear
    @helpers.options = RDoc::Options.new
  end

  describe "#git?" do
    it "returns false when git is not installed" do
      with_env("PATH" => "") do
        _(@helpers.git?).must_equal false
      end
    end

    it "returns false when project is not a git repository" do
      Dir.mktmpdir do |dir|
        @helpers.options.root = dir

        _(@helpers.git?).must_equal false
      end
    end
  end

  describe "#github_url" do
    before :each do
      @helpers.options.github = true
    end

    it "returns the URL for a given path in the project's GitHub repository at the current SHA1" do
      @helpers._git[:repo_path] = "path/to/repo"
      @helpers._git[:origin_url] = "git@github.com:user/repo.git"
      @helpers._git[:head_sha1] = "1337c0d3"

      _(@helpers.github_url("foo/bar/qux.rb")).
        must_equal "https://github.com/user/repo/blob/1337c0d3/foo/bar/qux.rb"
    end

    it "detects the GitHub repository name and current SHA1 (smoke test)" do
      _(@helpers.github_url("foo/bar/qux.rb")).
        must_match %r"\Ahttps://github.com/[^/]+/sdoc/blob/[0-9a-f]{40}/foo/bar/qux\.rb\z"
    end

    it "supports HTTPS remote URL" do
      @helpers._git[:origin_url] = "https://github.com/user/repo.git"

      _(@helpers.github_url("foo/bar/qux.rb")).
        must_match %r"\Ahttps://github.com/user/repo/blob/[0-9a-f]{40}/foo/bar/qux\.rb\z"
    end

    it "supports HTTPS remote URL without .git extension" do
      @helpers._git[:origin_url] = "https://github.com/user/repo"

      _(@helpers.github_url("foo/bar/qux.rb")).
        must_match %r"\Ahttps://github.com/user/repo/blob/[0-9a-f]{40}/foo/bar/qux\.rb\z"
    end

    it "returns nil when options.github is false" do
      @helpers.options.github = false

      _(@helpers.github_url("foo/bar/qux.rb")).must_be_nil
    end

    it "returns nil when git is not installed or project is not a git repository" do
      @helpers._git[:repo_path] = ""

      _(@helpers.github_url("foo/bar/qux.rb")).must_be_nil
    end

    it "returns nil when 'origin' remote is not present" do
      @helpers._git[:origin_url] = ""

      _(@helpers.github_url("foo/bar/qux.rb")).must_be_nil
    end

    it "returns nil when 'origin' remote is not recognized" do
      @helpers._git[:origin_url] = "git@gitlab.com:user/repo.git"

      _(@helpers.github_url("foo/bar/qux.rb")).must_be_nil
    end

    it "supports :line option" do
      _(@helpers.github_url("foo/bar/qux.rb", line: 123)).
        must_match %r"\Ahttps://github.com/.+/foo/bar/qux\.rb#L123\z"
    end
  end

  describe "#link_to" do
    it "returns a link tag" do
      _(@helpers.link_to("Foo::Bar::Qux", "foo/bar/qux.html")).
        must_equal %(<a href="foo/bar/qux.html">Foo::Bar::Qux</a>)
    end

    it "supports HTML attributes" do
      _(@helpers.link_to("foo", "bar", class: "qux", "data-hoge": "fuga")).
        must_equal %(<a href="bar" class="qux" data-hoge="fuga">foo</a>)
    end

    it "escapes the HTML attributes" do
      _(@helpers.link_to("Foo", "foo", title: "Foo < Object")).
        must_equal %(<a href="foo" title="Foo &lt; Object">Foo</a>)
    end

    it "does not escape the link body" do
      _(@helpers.link_to("<code>Foo</code>", "foo")).
        must_equal %(<a href="foo"><code>Foo</code></a>)
    end

    it "uses the first argument as the URL when no URL is specified" do
      _(@helpers.link_to("foo/bar/qux.html")).
        must_equal %(<a href="foo/bar/qux.html">foo/bar/qux.html</a>)

      _(@helpers.link_to("foo/bar/qux.html", "data-hoge": "fuga")).
        must_equal %(<a href="foo/bar/qux.html" data-hoge="fuga">foo/bar/qux.html</a>)
    end

    it "uses #full_name_for when the text argument is an RDoc::CodeObject" do
      top_level = rdoc_top_level_for <<~RUBY
        module Foo; class Bar; def qux; end; end; end
      RUBY

      [
        top_level,
        top_level.find_module_named("Foo"),
        top_level.find_module_named("Foo::Bar"),
        top_level.find_module_named("Foo::Bar").find_method("qux", false),
      ].each do |code_object|
        _(@helpers.link_to(code_object, "url")).
          must_equal %(<a href="url">#{@helpers.full_name_for(code_object)}</a>)
      end
    end

    it "uses RDoc::CodeObject#path as the URL when URL argument is an RDoc::CodeObject" do
      top_level = rdoc_top_level_for <<~RUBY
        module Foo; class Bar; def qux; end; end; end
      RUBY

      [
        top_level,
        top_level.find_module_named("Foo"),
        top_level.find_module_named("Foo::Bar"),
        top_level.find_module_named("Foo::Bar").find_method("qux", false),
      ].each do |code_object|
        _(@helpers.link_to("text", code_object)).
          must_equal %(<a href="/#{code_object.path}">text</a>)
      end
    end

    it "uses .ref-link as the default class when creating a <code> link to an RDoc::CodeObject" do
      rdoc_module = rdoc_top_level_for(<<~RUBY).find_module_named("Foo::Bar")
        module Foo; module Bar; end
      RUBY

      _(@helpers.link_to(rdoc_module)).
        must_equal %(<a href="/#{rdoc_module.path}" class="ref-link">#{@helpers.full_name_for(rdoc_module)}</a>)

      _(@helpers.link_to("<code>Bar</code>", rdoc_module)).
        must_equal %(<a href="/#{rdoc_module.path}" class="ref-link"><code>Bar</code></a>)

      _(@helpers.link_to("<code>Bar</code>", rdoc_module, class: "other")).
        must_equal %(<a href="/#{rdoc_module.path}" class="other"><code>Bar</code></a>)

      _(@helpers.link_to("Jump to <code>Bar</code>", rdoc_module)).
        must_equal %(<a href="/#{rdoc_module.path}">Jump to <code>Bar</code></a>)
    end
  end

  describe "#link_to_if" do
    it "returns the link's HTML when the condition is true" do
      args = ["<code>Foo</code>", "foo", title: "Foo < Object"]
      _(@helpers.link_to_if(true, *args)).must_equal @helpers.link_to(*args)
    end

    it "returns the link's inner HTML when the condition is false" do
      _(@helpers.link_to_if(false, "<code>Foo</code>", "url")).must_equal "<code>Foo</code>"

      rdoc_module = rdoc_top_level_for(<<~RUBY).find_module_named("Foo::Bar")
        module Foo; class Bar; end; end
      RUBY

      _(@helpers.link_to_if(false, rdoc_module, "url")).must_equal @helpers.full_name_for(rdoc_module)
    end
  end

  describe "#link_to_external" do
    it "sets class='external-link' and target='_blank' by default" do
      _(@helpers.link_to_external("foo", "bar")).
        must_equal %(<a href="bar" target="_blank" class="external-link">foo</a>)
    end

    it "supports additional classes" do
      _(@helpers.link_to_external("foo", "bar", class: "qux")).
        must_equal %(<a href="bar" target="_blank" class="qux external-link">foo</a>)
    end

    it "supports overriding target" do
      _(@helpers.link_to_external("foo", "bar", target: "_self")).
        must_equal %(<a href="bar" target="_self" class="external-link">foo</a>)
    end

    it "supports additional attributes" do
      _(@helpers.link_to_external("foo", "bar", "data-hoge": "fuga")).
        must_equal %(<a href="bar" target="_blank" class="external-link" data-hoge="fuga">foo</a>)
    end
  end

  describe "#button_to_search" do
    it "renders a button with the given query" do
      _(@helpers.button_to_search("Foo#<<")).must_equal <<~HTML.chomp
        <button class="query-button" data-query="Foo#&lt;&lt; ">Search <code>Foo#&lt;&lt;</code></button>
      HTML
    end

    it "uses RDoc::CodeObject#full_name for the query when given an RDoc::CodeObject" do
      rdoc_method = rdoc_top_level_for(<<~RUBY).find_module_named("Foo").find_method("<<", false)
        module Foo; def <<(*); end; end
      RUBY

      _(@helpers.button_to_search(rdoc_method)).must_equal <<~HTML.chomp
        <button class="query-button" data-query="Foo#&lt;&lt; ">Search <code>Foo#&lt;&lt;</code></button>
      HTML
    end

    it "supports overriding the displayed name" do
      _(@helpers.button_to_search("Foo::Bar", display_name: "<i>Bar<i>")).must_equal <<~HTML.chomp
        <button class="query-button" data-query="Foo::Bar ">Search <i>Bar<i></button>
      HTML
    end
  end

  describe "#full_name_for" do
    it "wraps name in <code>" do
      _(@helpers.full_name_for("Foo")).must_equal "<code>Foo</code>"
    end

    it "inserts word-break opportunities into module names" do
      _(@helpers.full_name_for("Foo::Bar::Qux")).must_equal "<code>Foo::<wbr>Bar::<wbr>Qux</code>"
      _(@helpers.full_name_for("::Foo::Bar::Qux")).must_equal "<code>::Foo::<wbr>Bar::<wbr>Qux</code>"
    end

    it "inserts word-break opportunities into file paths" do
      _(@helpers.full_name_for("path/to/file.rb")).must_equal "<code>path/<wbr>to/<wbr>file.rb</code>"
      _(@helpers.full_name_for("/path/to/file.rb")).must_equal "<code>/path/<wbr>to/<wbr>file.rb</code>"
    end

    it "escapes name parts" do
      _(@helpers.full_name_for("ruby&rails/file.rb")).must_equal "<code>ruby&amp;rails/<wbr>file.rb</code>"
    end

    it "uses RDoc::CodeObject#full_name when argument is an RDoc::CodeObject" do
      rdoc_module = rdoc_top_level_for(<<~RUBY).find_module_named("Foo::Bar::Qux")
        module Foo; module Bar; class Qux; end; end; end
      RUBY

      _(@helpers.full_name_for(rdoc_module)).must_equal "<code>Foo::<wbr>Bar::<wbr>Qux</code>"
    end
  end

  describe "#short_name_for" do
    it "wraps name in <code>" do
      _(@helpers.short_name_for("foo")).must_equal "<code>foo</code>"
    end

    it "escapes the name" do
      _(@helpers.short_name_for("<=>")).must_equal "<code>&lt;=&gt;</code>"
    end

    it "uses RDoc::CodeObject#name when argument is an RDoc::CodeObject" do
      rdoc_method = rdoc_top_level_for(<<~RUBY).find_module_named("Foo").find_method("bar", false)
        module Foo; def bar; end; end
      RUBY

      _(@helpers.short_name_for(rdoc_method)).must_equal "<code>bar</code>"
    end
  end

  describe "#description_for" do
    it "returns RDoc::CodeObject#description wrapped in div.description" do
      rdoc_module = rdoc_top_level_for(<<~RUBY).find_module_named("Foo")
        # This is +Foo+.
        module Foo; end
      RUBY

      _(@helpers.description_for(rdoc_module)).
        must_equal %(<div class="description">\n<p>This is <code>Foo</code>.</p>\n</div>)
    end

    it "returns nil when RDoc::CodeObject#description is empty" do
      rdoc_module = rdoc_top_level_for(<<~RUBY).find_module_named("Foo")
        module Foo; end
      RUBY

      _(@helpers.description_for(rdoc_module)).must_be_nil
    end
  end

  describe "#base_tag_for_context" do
    it "returns a <base> tag with an appropriate path for the given RDoc::Context" do
      top_level = rdoc_top_level_for <<~RUBY
        module Foo; module Bar; module Qux; end; end; end
      RUBY

      _(@helpers.base_tag_for_context(top_level.find_module_named("Foo"))).
        must_equal %(<base href="./../" data-current-path="classes/Foo.html">)

      _(@helpers.base_tag_for_context(top_level.find_module_named("Foo::Bar"))).
        must_equal %(<base href="./../../" data-current-path="classes/Foo/Bar.html">)

      _(@helpers.base_tag_for_context(top_level.find_module_named("Foo::Bar::Qux"))).
        must_equal %(<base href="./../../../" data-current-path="classes/Foo/Bar/Qux.html">)
    end
  end

  describe "#canonical_url" do
    it "returns a URL based on ENV['HORO_CANONICAL_URL'] for an RDoc::Context" do
      context = rdoc_top_level_for(<<~RUBY).find_module_named("Foo::Bar::Qux")
        module Foo; module Bar; module Qux; end; end; end
      RUBY

      with_env("HORO_CANONICAL_URL" => "https://canonical") do
        _(@helpers.canonical_url(context)).must_equal "https://canonical/classes/Foo/Bar/Qux.html"
      end
    end

    it "returns a URL based on ENV['HORO_CANONICAL_URL'] for a path" do
      with_env("HORO_CANONICAL_URL" => "https://canonical") do
        _(@helpers.canonical_url("/path/to/foo")).must_equal "https://canonical/path/to/foo"
        _(@helpers.canonical_url("path/to/foo")).must_equal "https://canonical/path/to/foo"
      end
    end

    it "returns a URL based on ENV['HORO_CANONICAL_URL'] for nil" do
      with_env("HORO_CANONICAL_URL" => "https://canonical") do
        _(@helpers.canonical_url(nil)).must_equal "https://canonical/"
      end
    end

    it "returns nil when ENV['HORO_CANONICAL_URL'] is not set" do
      with_env("HORO_CANONICAL_URL" => nil) do
        _(@helpers.canonical_url(nil)).must_be_nil
      end
    end
  end

  describe "#project_name" do
    it "returns escaped name from ENV['HORO_PROJECT_NAME']" do
      with_env("HORO_PROJECT_NAME" => "Ruby & Rails") do
        _(@helpers.project_name).must_equal "Ruby &amp; Rails"
      end
    end

    it "returns nil when ENV['HORO_PROJECT_NAME'] is not set" do
      with_env("HORO_PROJECT_NAME" => nil) do
        _(@helpers.project_name).must_be_nil
      end
    end
  end

  describe "#project_version" do
    it "returns escaped version from ENV['HORO_PROJECT_VERSION']" do
      with_env("HORO_PROJECT_VERSION" => "~> 1.0.0") do
        _(@helpers.project_version).must_equal "~&gt; 1.0.0"
      end
    end

    it "prioritizes ENV['HORO_BADGE_VERSION'] over ENV['HORO_PROJECT_VERSION']" do
      with_env("HORO_BADGE_VERSION" => "badge", "HORO_PROJECT_VERSION" => "project") do
        _(@helpers.project_version).must_equal "badge"
      end
    end

    it "returns nil when neither ENV['HORO_BADGE_VERSION'] nor ENV['HORO_PROJECT_VERSION'] are set" do
      with_env("HORO_BADGE_VERSION" => nil, "HORO_PROJECT_VERSION" => nil) do
        _(@helpers.project_version).must_be_nil
      end
    end
  end

  describe "#project_git_head" do
    it "returns the branch name and abbreviated SHA1 of the most recent commit in HEAD" do
      @helpers._git[:repo_path] = "path/to/repo"
      @helpers._git[:head_branch] = "1-0-stable"
      @helpers._git[:head_sha1] = "1337c0d3d00d" * 3

      _(@helpers.project_git_head).must_equal "1-0-stable@1337c0d3d00d"
    end

    it "returns the branch name and abbreviated SHA1 of the most recent commit in HEAD (smoke test)" do
      _(@helpers.project_git_head).must_match %r"\A.+@[[:xdigit:]]{12}\z"
    end

    it "returns nil when git is not installed or project is not a git repository" do
      @helpers._git[:repo_path] = ""

      _(@helpers.project_git_head).must_be_nil
    end
  end

  describe "#page_title" do
    it "includes options.title" do
      @helpers.options.title = "My Docs"

      _(@helpers.page_title).must_equal "My Docs"
      _(@helpers.page_title("Foo")).must_equal "Foo - My Docs"
    end

    it "escapes the title" do
      @helpers.options.title = "Docs & Stuff"

      _(@helpers.page_title("Foo<Bar>")).must_equal "Foo&lt;Bar&gt; - Docs &amp; Stuff"
    end
  end

  describe "#og_title" do
    it "includes ENV['HORO_PROJECT_NAME'] and ENV['HORO_PROJECT_VERSION']" do
      with_env("HORO_PROJECT_NAME" => "My Gem", "HORO_PROJECT_VERSION" => "v2.0") do
        _(@helpers.og_title("Foo")).must_equal "Foo (My Gem v2.0)"
      end

      with_env("HORO_PROJECT_NAME" => "My Gem", "HORO_PROJECT_VERSION" => nil) do
        _(@helpers.og_title("Foo")).must_equal "Foo (My Gem)"
      end

      with_env("HORO_PROJECT_NAME" => nil, "HORO_PROJECT_VERSION" => "v2.0") do
        _(@helpers.og_title("Foo")).must_equal "Foo (v2.0)"
      end

      with_env("HORO_PROJECT_NAME" => nil, "HORO_PROJECT_VERSION" => nil) do
        _(@helpers.og_title("Foo")).must_equal "Foo"
      end
    end

    it "escapes the title" do
      with_env("HORO_PROJECT_NAME" => "Ruby & Rails", "HORO_PROJECT_VERSION" => "~> 1.0.0") do
        _(@helpers.og_title("Foo<Bar>")).must_equal "Foo&lt;Bar&gt; (Ruby &amp; Rails ~&gt; 1.0.0)"
      end
    end
  end

  describe "#og_modified_time" do
    it "returns the commit time of the most recent commit in HEAD" do
      @helpers._git[:repo_path] = "path/to/repo"
      @helpers._git[:head_timestamp] = "1999-12-31T12:34:56Z"

      _(@helpers.og_modified_time).must_equal "1999-12-31T12:34:56Z"
    end

    it "returns the commit time of the most recent commit in HEAD (smoke test)" do
      _(@helpers.og_modified_time).
        must_match %r"\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[-+]\d{2}:\d{2}\z"
    end

    it "returns nil when git is not installed or project is not a git repository" do
      @helpers._git[:repo_path] = ""

      _(@helpers.og_modified_time).must_be_nil
    end
  end

  describe "#page_description" do
    it "extracts the description from the leading paragraph" do
      _(@helpers.page_description(<<~HTML)).must_equal "leading"
        <p>leading</p>
        <p>other</p>
      HTML

      _(@helpers.page_description(<<~HTML)).must_equal "paragraph"
        <h1>headline</h1>
        <p>paragraph</p>
      HTML

      _(@helpers.page_description(<<~HTML)).must_equal "paragraph"
        <h1>1</h1><h2>2</h2><h3>3</h3><h4>4</h4><h5>5</h5><h6>6</h6>
        <p>paragraph</p>
      HTML
    end

    it "returns nil when there is no leading paragraph" do
      _(@helpers.page_description(<<~HTML)).must_be_nil
        <pre><code>code</code></pre>
        <p>other</p>
      HTML

      _(@helpers.page_description(<<~HTML)).must_be_nil
        <ul><li><p>item</p></li></ul>
        <p>other</p>
      HTML

      _(@helpers.page_description("")).must_be_nil
      _(@helpers.page_description(nil)).must_be_nil
    end

    it "strips HTML tags" do
      _(@helpers.page_description(<<~HTML)).must_equal "emphatic text"
        <p><em>emphatic</em> text</p>
      HTML
    end

    it "escapes the text" do
      _(@helpers.page_description(<<~HTML)).must_equal "x &lt; y"
        <p>x &lt; y</p>
      HTML
    end

    it "truncates at word boundaries" do
      leading_html = "<p>12345 78. 12, 5 - 9.</p>"

      {
         8..10 => "12345...",
        11..14 => "12345 78...",
        15..17 => "12345 78. 12...",
        18..19 => "12345 78. 12, 5...",
        20..25 => "12345 78. 12, 5 - 9.",
      }.each do |range, expected|
        range.each do |max_length|
          _(@helpers.page_description(leading_html, max_length: max_length)).must_equal expected
        end
      end
    end

    it "truncates to 160 characters by default" do
      _(@helpers.page_description("<p>#{"x" * 150}123 567 9.</p>")).
        must_equal "#{"x" * 150}123 567 9."

      _(@helpers.page_description("<p>#{"x" * 150}123 567 xxx.</p>")).
        must_equal "#{"x" * 150}123 567..."
    end
  end

  describe "#outline" do
    def expected(html, context:)
      html.gsub(/\s/, "").gsub(/<li>([^<]+)/, '<li><a href="#' + context.aref + '-label-\1">\1</a>')
    end

    it "renders a nested list of heading links" do
      context = rdoc_top_level_for(<<~RUBY).find_module_named("Foo")
        # == L2-1
        # == L2-2
        # === L3-1
        # ==== L4-1
        # ===== L5-1
        # ====== L6-1
        # == L2-3
        module Foo; end
      RUBY

      _(@helpers.outline(context)).must_equal expected(<<~HTML, context: context)
        <ul>
          <li>L2-1</li>
          <li>L2-2 <ul>
            <li>L3-1 <ul>
              <li>L4-1 <ul>
                <li>L5-1 <ul>
                  <li>L6-1</li>
                </ul></li>
              </ul></li>
            </ul></li>
          </ul></li>
          <li>L2-3</li>
        </ul>
      HTML
    end

    it "handles skipped heading levels" do
      context = rdoc_top_level_for(<<~RUBY).find_module_named("Foo")
        # === L3-1
        # ===== L5-1
        # == L2-1
        # ==== L4-1
        module Foo; end
      RUBY

      _(@helpers.outline(context)).must_equal expected(<<~HTML, context: context)
        <ul>
          <li>L3-1 <ul>
            <li>L5-1</li>
          </ul></li>
          <li>L2-1 <ul>
            <li>L4-1</li>
          </ul></li>
        </ul>
      HTML
    end

    it "omits the h1 heading when it is primary" do
      context = rdoc_top_level_for(<<~RUBY).find_module_named("Foo")
        # = L1-1
        # == L2-1
        # === L3-1
        # == L2-2
        module Foo; end
      RUBY

      _(@helpers.outline(context)).must_equal expected(<<~HTML, context: context)
        <ul>
          <li>L2-1 <ul>
            <li>L3-1</li>
          </ul></li>
          <li>L2-2</li>
        </ul>
      HTML
    end

    it "preserves all h1 headings when any are non-primary" do
      context = rdoc_top_level_for(<<~RUBY).find_module_named("Foo")
        # = L1-1
        # == L2-1
        # = L1-2
        module Foo; end
      RUBY

      _(@helpers.outline(context)).must_equal expected(<<~HTML, context: context)
        <ul>
          <li>L1-1 <ul>
            <li>L2-1</li>
          </ul></li>
          <li>L1-2</li>
        </ul>
      HTML
    end
  end

  describe "#more_less_ul" do
    def ul(items)
      ["<ul>", *items.map { |item| "<li>#{item}</li>" }, "</ul>"].join
    end

    it "returns a single list when the number of items is <= hard limit" do
      _(@helpers.more_less_ul(1..7, 7)).must_equal ul(1..7)
      _(@helpers.more_less_ul(1..7, 8)).must_equal ul(1..7)

      _(@helpers.more_less_ul(1..7, 6..7)).must_equal ul(1..7)
      _(@helpers.more_less_ul(1..7, 6..8)).must_equal ul(1..7)

      _(@helpers.more_less_ul(1..7, 7..9)).must_equal ul(1..7)
      _(@helpers.more_less_ul(1..7, 8..9)).must_equal ul(1..7)
    end

    it "returns split lists when the number of items is > hard limit" do
      _(@helpers.more_less_ul(1..7, 6)).must_match %r"#{ul 1..6}.*<details.+#{ul 7..7}.*</details>"m
      _(@helpers.more_less_ul(1..7, 5)).must_match %r"#{ul 1..5}.*<details.+#{ul 6..7}.*</details>"m

      _(@helpers.more_less_ul(1..7, 5..6)).must_match %r"#{ul 1..5}.*<details.+#{ul 6..7}.*</details>"m
      _(@helpers.more_less_ul(1..7, 4..6)).must_match %r"#{ul 1..4}.*<details.+#{ul 5..7}.*</details>"m
    end

    it "specifies the number of hidden items" do
      _(@helpers.more_less_ul(1..7, 4)).must_match %r"\b3 More\b"
    end

    it "does not escape items" do
      _(@helpers.more_less_ul(["<a>link</a>"], 1)).must_include "<a>link</a>"
    end
  end

  describe "#top_modules" do
    it "returns top-level classes and modules in sorted order" do
      top_level = rdoc_top_level_for <<~RUBY
        class Foo; module Hoge; end; end
        module Bar; class Fuga; end; end
      RUBY

      _(@helpers.top_modules(top_level.store)).
        must_equal [top_level.find_module_named("Bar"), top_level.find_module_named("Foo")]
    end

    it "handles flattened class and module declarations" do
      top_level = rdoc_top_level_for <<~RUBY
        class Foo::Hoge; end
        module Bar::Fuga; end
      RUBY

      _(@helpers.top_modules(top_level.store)).
        must_equal [top_level.find_module_named("Bar"), top_level.find_module_named("Foo")]
    end

    it "excludes core extensions (based on options.core_ext_pattern)" do
      top_level = rdoc_top_level_for <<~RUBY
        module Foo; end
      RUBY

      @helpers.options.core_ext_pattern = /#{Regexp.escape top_level.name}/

      _(@helpers.top_modules(top_level.store)).must_be_empty
    end
  end

  describe "#core_extensions" do
    it "returns top-level core extensions in sorted order (based on options.core_ext_pattern)" do
      top_level = rdoc_top_level_for <<~RUBY
        class Foo; module Hoge; end; end
        module Bar; class Fuga; end; end
      RUBY

      _(@helpers.core_extensions(top_level.store)).must_be_empty

      @helpers.options.core_ext_pattern = /#{Regexp.escape top_level.name}/

      _(@helpers.core_extensions(top_level.store)).
        must_equal [top_level.find_module_named("Bar"), top_level.find_module_named("Foo")]
    end
  end

  describe "#module_breadcrumbs" do
    it "renders links for each of the module's parents" do
      top_level = rdoc_top_level_for <<~RUBY
        module Foo; module Bar; module Qux; end; end; end
      RUBY

      foo = top_level.find_module_named("Foo")
      bar = top_level.find_module_named("Foo::Bar")
      qux = top_level.find_module_named("Foo::Bar::Qux")

      _(@helpers.module_breadcrumbs(foo)).
        must_equal "<code>Foo</code>"

      _(@helpers.module_breadcrumbs(bar)).
        must_equal "<code>#{@helpers.link_to "Foo", foo}::<wbr>Bar</code>"

      _(@helpers.module_breadcrumbs(qux)).
        must_equal "<code>#{@helpers.link_to "Foo", foo}::<wbr>#{@helpers.link_to "Bar", bar}::<wbr>Qux</code>"
    end

    it "handles flattened class declarations" do
      top_level = rdoc_top_level_for <<~RUBY
        class Foo::Bar::Qux; end
      RUBY

      foo = top_level.find_module_named("Foo")
      bar = top_level.find_module_named("Foo::Bar")
      qux = top_level.find_module_named("Foo::Bar::Qux")

      _(@helpers.module_breadcrumbs(qux)).
        must_equal "<code>#{@helpers.link_to "Foo", foo}::<wbr>#{@helpers.link_to "Bar", bar}::<wbr>Qux</code>"
    end
  end

  describe "#module_ancestors" do
    it "returns a list with the base class (if applicable) and included modules" do
      # RDoc chokes on ";" when parsing includes, so replace with "\n".
      top_level = rdoc_top_level_for <<~RUBY.gsub(";", "\n")
        module M1; end
        module M2; end
        class C1; end

        module Foo; include M1; include M2; end
        class Bar < C1; include M2; include M1; end
        class Qux < Cx; include Foo; include Mx; end
      RUBY

      m1, m2, c1, foo, bar, qux = %w[M1 M2 C1 Foo Bar Qux].map { |name| top_level.find_module_named(name) }

      _(@helpers.module_ancestors(foo)).must_equal [["module", m1], ["module", m2]]
      _(@helpers.module_ancestors(bar)).must_equal [["class", c1], ["module", m2], ["module", m1]]
      _(@helpers.module_ancestors(qux)).must_equal [["class", "Cx"], ["module", foo], ["module", "Mx"]]
    end

    it "excludes the default base class (Object) from the result" do
      # RDoc chokes on ";" when parsing includes, so replace with "\n".
      top_level = rdoc_top_level_for <<~RUBY.gsub(";", "\n")
        class Object; end
        class Foo; include M1; end
      RUBY

      _(@helpers.module_ancestors(top_level.find_module_named("Object"))).must_equal [["class", "BasicObject"]]
      _(@helpers.module_ancestors(top_level.find_module_named("Foo"))).must_equal [["module", "M1"]]

      top_level = rdoc_top_level_for <<~RUBY.gsub(";", "\n")
        class Foo; include M1; end
      RUBY

      _(@helpers.module_ancestors(top_level.find_module_named("Foo"))).must_equal [["module", "M1"]]
    end
  end

  describe "#module_methods" do
    it "returns all methods of a given module, sorted by definition scope and name" do
      rdoc_module = rdoc_top_level_for(<<~RUBY).find_module_named("Foo")
        module Foo
          def foo; end
          class << self
            private def foo; end
          end
          private def bar; end
          def self.bar; end
        end
      RUBY

      _(@helpers.module_methods(rdoc_module)).must_equal [
        rdoc_module.find_method("bar", true),
        rdoc_module.find_method("foo", true),
        rdoc_module.find_method("bar", false),
        rdoc_module.find_method("foo", false),
      ]
    end
  end

  describe "#method_signature" do
    it "returns the method signature wrapped in <code>" do
      method = rdoc_top_level_for(<<~RUBY).find_module_named("Foo").find_method("bar", false)
        module Foo; def bar(qux); end; end
      RUBY

      _(@helpers.method_signature(method)).must_equal "<code><b>bar</b>(qux)</code>"
    end

    it "escapes the method signature" do
      method = rdoc_top_level_for(<<~RUBY).find_module_named("Foo").find_method("bar", false)
        module Foo; def bar(op = :<, &block); end; end
      RUBY

      _(@helpers.method_signature(method)).must_equal "<code><b>bar</b>(op = :&lt;, &amp;block)</code>"
    end

    it "handles :call-seq: documentation" do
      mod = rdoc_top_level_for(<<~RUBY).find_module_named("Foo")
        module Foo
          # :call-seq:
          #   bar(op = :<)
          #   bar(&block)
          def bar(*args, &block); end

          # :call-seq:
          #   qux(&block) -> self
          #   qux -> Enumerator
          def qux(&block); end
        end
      RUBY

      _(@helpers.method_signature(mod.find_method("bar", false))).must_equal <<~HTML.chomp
        <code><b>bar</b>(op = :&lt;)
        <b>bar</b>(&amp;block)</code>
      HTML

      _(@helpers.method_signature(mod.find_method("qux", false))).must_equal <<~HTML.chomp
        <code><b>qux</b>(&amp;block) <span class="returns">&rarr;</span> self
        <b>qux</b> <span class="returns">&rarr;</span> Enumerator</code>
      HTML
    end
  end

  describe "#method_source_code_and_url" do
    before :each do
      @helpers.options.github = true
    end

    it "returns source code and GitHub URL for a given RDoc::AnyMethod" do
      method = rdoc_top_level_for(<<~RUBY).find_module_named("Foo").find_method("bar", false)
        module Foo # line 1
          def bar # line 2
            # line 3
          end
        end
      RUBY

      source_code, source_url = @helpers.method_source_code_and_url(method)

      _(source_code).must_match %r"# File .+\.rb, line 2\b"
      _(source_code).must_include "line 3"
      _(source_url).must_match %r"\Ahttps://github.com/.+\.rb#L2\z"
    end

    it "returns nil source code when given method is an RDoc::GhostMethod" do
      method = rdoc_top_level_for(<<~RUBY).find_module_named("Foo").find_method("bar", false)
        module Foo # line 1
          ##
          # :method: bar
        end
      RUBY

      source_code, source_url = @helpers.method_source_code_and_url(method)

      _(source_code).must_be_nil
      _(source_url).must_match %r"\Ahttps://github.com/.+\.rb#L3\z"
    end

    it "returns nil source code when given method is an alias" do
      method = rdoc_top_level_for(<<~RUBY).find_module_named("Foo").find_method("bar", false)
        module Foo # line 1
          def qux; end
          alias bar qux
        end
      RUBY

      source_code, _source_url = @helpers.method_source_code_and_url(method)

      _(source_code).must_be_nil
      # Unfortunately, _source_url is also nil because RDoc does not provide the
      # source code location in this case.
    end

    it "returns nil GitHub URL when options.github is false" do
      @helpers.options.github = false

      method = rdoc_top_level_for(<<~RUBY).find_module_named("Foo").find_method("bar", false)
        module Foo # line 1
          def bar; end # line 2
        end
      RUBY

      source_code, source_url = @helpers.method_source_code_and_url(method)

      _(source_code).must_match %r"# File .+\.rb, line 2\b"
      _(source_url).must_be_nil
    end
  end
end
