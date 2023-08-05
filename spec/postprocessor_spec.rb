require "spec_helper"

describe SDoc::Postprocessor do
  describe "#process" do
    it "rebases URLs" do
      rendered = <<~HTML
        <base href="../../" data-current-path="foo/bar/current.html">

        <link href="/stylesheet.css" rel="stylesheet">
        <script src="/javascript.js"></script>

        <a href="#section">Link</a>
        <img src="image.png">
      HTML

      expected_head = <<~HTML
        <link href="stylesheet.css" rel="stylesheet">
        <script src="javascript.js"></script>
      HTML

      expected_body = <<~HTML
        <a href="foo/bar/current.html#section">Link</a>
        <img src="foo/bar/image.png">
      HTML

      postprocessed = SDoc::Postprocessor.process(rendered)

      _(postprocessed).must_include expected_head
      _(postprocessed).must_include expected_body
    end

    it "versions Rails guides URLs based on ENV['HORO_PROJECT_VERSION']" do
      rendered = <<~HTML
        <a href="https://guides.rubyonrails.org/testing.html">Testing</a>
      HTML

      with_env("HORO_PROJECT_VERSION" => "3.2.1", "HORO_PROJECT_NAME" => "Ruby on Rails") do
        _(SDoc::Postprocessor.process(rendered)).
          must_include %(<a href="https://guides.rubyonrails.org/v3.2.1/testing.html">Testing</a>)
      end

      with_env("HORO_PROJECT_VERSION" => "main@1337c0d3", "HORO_PROJECT_NAME" => "Ruby on Rails") do
        _(SDoc::Postprocessor.process(rendered)).
          must_include %(<a href="https://edgeguides.rubyonrails.org/testing.html">Testing</a>)
      end

      with_env("HORO_PROJECT_VERSION" => nil, "HORO_PROJECT_NAME" => "Ruby on Rails") do
        _(SDoc::Postprocessor.process(rendered)).
          must_include %(<a href="https://guides.rubyonrails.org/testing.html">Testing</a>)
      end
    end

    it "does not version Rails guides URLs when ENV['HORO_PROJECT_NAME'] is not Ruby on Rails" do
      rendered = <<~HTML
        <a href="https://guides.rubyonrails.org/testing.html">Testing</a>
      HTML

      with_env("HORO_PROJECT_VERSION" => "3.2.1", "HORO_PROJECT_NAME" => "My Rails Gem") do
        _(SDoc::Postprocessor.process(rendered)).
          must_include %(<a href="https://guides.rubyonrails.org/testing.html">Testing</a>)
      end
    end

    it "unlinks unintentional autolinked code ref links in descriptions" do
      rendered = <<~HTML
        <base href="../" data-current-path="classes/Foo.html">

        <div class="description">
          <a href="Rails.html"><code>Rails</code></a>
          <a href="ERB.html"><code>ERB</code></a>

          <a href="Rails.html"><code>::Rails</code></a>
          <a href="FooBar.html"><code>FooBar</code></a>
        </div>

        <a href="Nav.html"><code>Nav</code></a>
      HTML

      expected = <<~HTML
        <div class="description">
          Rails
          ERB

          <a href="classes/Rails.html"><code>::Rails</code></a>
          <a href="classes/FooBar.html"><code>FooBar</code></a>
        </div>

        <a href="classes/Nav.html"><code>Nav</code></a>
      HTML

      _(SDoc::Postprocessor.process(rendered)).must_include expected
    end

    it "styles unstyled code ref links in descriptions" do
      rendered = <<~HTML
        <base href="../" data-current-path="classes/Foo.html">

        <div class="description">
          <a href="/classes/Bar/Qux.html">Qux</a>
          <a href="Bar/Qux.html">Qux</a>
          <a href="#method-i-bar-3F.html">Foo#bar?(qux, &amp;block)</a>
          <a href="#method-i-2A_bar-21.html">*_bar!</a>

          <a href="https://example.com/Qux.html">Qux</a>
          <a href="Bar/Qux.html">Not Code</a>
          <a href="Bar/Qux.html">(also) not code</a>
        </div>

        <a href="/classes/Permalink.html">Permalink</a>
      HTML

      expected = <<~HTML
        <div class="description">
          <a href="classes/Bar/Qux.html"><code>Qux</code></a>
          <a href="classes/Bar/Qux.html"><code>Qux</code></a>
          <a href="classes/Foo.html#method-i-bar-3F.html"><code>Foo#bar?(qux, &amp;block)</code></a>
          <a href="classes/Foo.html#method-i-2A_bar-21.html"><code>*_bar!</code></a>

          <a href="https://example.com/Qux.html">Qux</a>
          <a href="classes/Bar/Qux.html">Not Code</a>
          <a href="classes/Bar/Qux.html">(also) not code</a>
        </div>

        <a href="classes/Permalink.html">Permalink</a>
      HTML

      _(SDoc::Postprocessor.process(rendered)).must_include expected
    end

    it "highlights code blocks" do
      rendered = <<~HTML
        <div class="description">
          <p>Ruby:</p>
          <pre><code>1 + 1</code></pre>
          <p>ERB:</p>
          <pre><code>&lt;%= 1 + 1 %&gt;</code></pre>
        </div>
      HTML

      expected = <<~HTML
        <div class="description">
          <p>Ruby:</p>
          <pre><code class="highlight ruby">#{SDoc::Postprocessor.highlight_code("1 + 1", "ruby")}</code></pre>
          <p>ERB:</p>
          <pre><code class="highlight erb">#{SDoc::Postprocessor.highlight_code("<%= 1 + 1 %>", "erb")}</code></pre>
        </div>
      HTML

      _(SDoc::Postprocessor.process(rendered)).must_include expected
    end

    it "highlights method source code" do
      rendered = <<~HTML
        <div class="sourcecode">
          <pre><code class="ruby"><span class="ruby-comment"># highlighted by RDoc</span></code></pre>
        </div>

        <div class="sourcecode">
          <pre><code class="ruby">DELETE FROM 'tricky_ruby'</code></pre>
        </div>
      HTML

      expected = <<~HTML
        <div class="sourcecode">
          <pre><code class="ruby highlight">#{SDoc::Postprocessor.highlight_code("# highlighted by RDoc", "ruby")}</code></pre>
        </div>

        <div class="sourcecode">
          <pre><code class="ruby highlight">#{SDoc::Postprocessor.highlight_code("DELETE FROM 'tricky_ruby'", "ruby")}</code></pre>
        </div>
      HTML

      _(SDoc::Postprocessor.process(rendered)).must_include expected
    end
  end

  describe "#rebase_url" do
    it "does not change full URLs" do
      [
        "//example.com/hoge/fuga",
        "https://example.com/hoge/fuga",
        "http://example.com/hoge/fuga",
        "javascript:alert('hoge')",
        "data:,hoge",
      ].each do |url|
        _(SDoc::Postprocessor.rebase_url(url, "foo/bar/qux.html")).must_equal url
      end
    end

    it "changes absolute paths to relative (to the expected <base> element)" do
      _(SDoc::Postprocessor.rebase_url("/hoge/fuga.html", "foo/bar/qux.html")).
        must_equal "hoge/fuga.html"
    end

    it "expands relative paths" do
      _(SDoc::Postprocessor.rebase_url("hoge/fuga.html", "foo/bar/qux.html")).
        must_equal "foo/bar/hoge/fuga.html"

      _(SDoc::Postprocessor.rebase_url("../hoge/fuga.html", "foo/bar/qux.html")).
        must_equal "foo/hoge/fuga.html"
    end

    it "expands fragments" do
      _(SDoc::Postprocessor.rebase_url("#hoge", "foo/bar/qux.html")).
        must_equal "foo/bar/qux.html#hoge"
    end
  end

  describe "#version_url" do
    it "prepends the version number to the URL's path" do
      _(SDoc::Postprocessor.version_url("https://example.com/foo/bar.html", "3.2.1")).
        must_equal "https://example.com/v3.2.1/foo/bar.html"
    end

    it "does not prepend the version number when the URL is already versioned" do
      [
        "https://example.com/v1/foo/bar.html",
        "https://example.com/v1.2/foo/bar.html",
        "https://example.com/v1.2.3/foo/bar.html",
        "https://example.com/v1.2.3.4/foo/bar.html",
      ].each do |url|
        _(SDoc::Postprocessor.version_url(url, "3.2.1")).must_equal url
      end
    end

    it "prepends 'edge' to the URL's host when the version is not a number" do
      _(SDoc::Postprocessor.version_url("https://api.example.com/foo/bar.html", "main@1337c0d3")).
        must_equal "https://edgeapi.example.com/foo/bar.html"
    end
  end

  describe "#highlight_code" do
    it "returns highlighted HTML" do
      _(SDoc::Postprocessor.highlight_code("1 + 1", "ruby")).
        must_equal %{<span class="mi">1</span> <span class="o">+</span> <span class="mi">1</span>}

      _(SDoc::Postprocessor.highlight_code("$ rails s", "console")).
        must_equal %{<span class="gp">$</span><span class="w"> </span>rails s}
    end
  end

  describe "#guess_code_language" do
    it "guesses console for CLI session" do
      _(SDoc::Postprocessor.guess_code_language(<<~CLI)).must_equal "console"
        $ rails server
        Booting
      CLI
    end

    it "guesses plaintext for ASCII-art table" do
      _(SDoc::Postprocessor.guess_code_language(<<~TABLE)).must_equal "plaintext"
        a | b
        --+--
        1 | 2
      TABLE

      _(SDoc::Postprocessor.guess_code_language(<<~TABLE)).must_equal "plaintext"
        a | b
        --|--
        1 | 2
      TABLE
    end

    it "guesses plaintext for routes listing" do
      _(SDoc::Postprocessor.guess_code_language(<<~ROUTES)).must_equal "plaintext"
        post GET    /posts/:id(.:format)      posts#show
             DELETE /posts/:id(.:format)      posts#destroy
      ROUTES

      _(SDoc::Postprocessor.guess_code_language(<<~ROUTES)).must_equal "plaintext"
        DELETE /posts/:id
      ROUTES
    end

    it "guesses sql for SQL query" do
      _(SDoc::Postprocessor.guess_code_language(<<~SQL)).must_equal "sql"
        SELECT * FROM posts
      SQL

      _(SDoc::Postprocessor.guess_code_language(<<~SQL)).must_equal "sql"
        DELETE FROM posts WHERE id = 1
      SQL
    end

    it "guesses email for email message" do
      _(SDoc::Postprocessor.guess_code_language(<<~EMAIL)).must_equal "email"
        To: recipient@example.com
      EMAIL

      _(SDoc::Postprocessor.guess_code_language(<<~EMAIL)).must_equal "email"
        Cc: recipient@example.com
      EMAIL

      _(SDoc::Postprocessor.guess_code_language(<<~EMAIL)).must_equal "email"
        Bcc: recipient@example.com
      EMAIL
    end

    it "guesses yaml for YAML" do
      _(SDoc::Postprocessor.guess_code_language(<<~YAML)).must_equal "yaml"
        foo:
          bar: 1
      YAML

      _(SDoc::Postprocessor.guess_code_language(<<~YAML)).must_equal "yaml"
        foo: # comment
          bar: 1
      YAML

      _(SDoc::Postprocessor.guess_code_language(<<~YAML)).must_equal "yaml"
        base: &base
          baz: 1

        foo:
          <<: *base
          bar: 2
      YAML

      _(SDoc::Postprocessor.guess_code_language(<<~YAML)).must_equal "yaml"
        foo: |
          bar
      YAML

      _(SDoc::Postprocessor.guess_code_language(<<~YAML)).must_equal "yaml"
        foo: >
          bar
      YAML
    end

    it "guesses erb for YAML that includes ERB" do
      _(SDoc::Postprocessor.guess_code_language(<<~ERB)).must_equal "erb"
        foo:
          bar: <%= 1 + 1 %>
      ERB
    end

    it "guesses plaintext for YAML that includes ERB and HTML-incompatible markup" do
      _(SDoc::Postprocessor.guess_code_language(<<~ERB)).must_equal "plaintext"
        base: &base
          baz: 1

        foo:
          <<: *base
          bar: <%= 1 + 1 %>
      ERB
    end

    it "guesses erb for ERB" do
      _(SDoc::Postprocessor.guess_code_language(<<~ERB)).must_equal "erb"
        <%= 1 + 1 %>
      ERB

      _(SDoc::Postprocessor.guess_code_language(<<~ERB)).must_equal "erb"
        <% x = 1 + 1 %>
      ERB

      _(SDoc::Postprocessor.guess_code_language(<<~ERB)).must_equal "erb"
        <%- x = 1 + 1 -%>
      ERB
    end

    it "guesses erb for HTML" do
      _(SDoc::Postprocessor.guess_code_language(<<~HTML)).must_equal "erb"
        <p>1 + 1 = 2</p>
      HTML
    end

    it "guesses erb for HTML that includes ERB" do
      _(SDoc::Postprocessor.guess_code_language(<<~ERB)).must_equal "erb"
        <p>1 + 1 = <%= 1 + 1 %></p>
      ERB
    end

    it "guesses ruby for Ruby code" do
      _(SDoc::Postprocessor.guess_code_language(<<~RUBY)).must_equal "ruby"
        1 + 1
      RUBY
    end

    it "guesses ruby for Ruby return value comment" do
      _(SDoc::Postprocessor.guess_code_language(<<~RUBY)).must_equal "ruby"
        Object.new # => #<Object>
      RUBY

      _(SDoc::Postprocessor.guess_code_language(<<~RUBY)).must_equal "ruby"
        image_tag("image.png")
        # => <img src="/assets/image.png" />
      RUBY
    end

    it "guesses ruby for Ruby code that includes an ERB string" do
      _(SDoc::Postprocessor.guess_code_language(<<~RUBY)).must_equal "ruby"
        ApplicationController.render inline: "<%= 1 + 1 %>"
      RUBY
    end

    it "guesses ruby by default" do
      _(SDoc::Postprocessor.guess_code_language(<<~RUBY)).must_equal "ruby"
        f x
      RUBY
    end
  end
end
