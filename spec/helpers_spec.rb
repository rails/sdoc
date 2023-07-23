require "spec_helper"

describe SDoc::Helpers do
  before :each do
    @helpers = Class.new do
      include ERB::Util
      include SDoc::Helpers
    end.new
  end

  describe "#strip_tags" do
    it "should strip out HTML tags from the given string" do
      strings = [
        [ %(<strong>Hello world</strong>),                                      "Hello world"          ],
        [ %(<a href="Streams.html">Streams</a> are great),                      "Streams are great"    ],
        [ %(<a href="https://github.com?x=1&y=2#123">zzak/sdoc</a> Standalone), "zzak/sdoc Standalone" ],
        [ %(<h1 id="module-AR::Cb-label-Foo+Bar">AR Cb</h1>),                   "AR Cb"                ],
        [ %(<a href="../Base.html">Base</a>),                                   "Base"                 ],
        [ %(Some<br>\ntext),                                                    "Some\ntext"           ]
      ]

      strings.each do |(html, stripped)|
        _(@helpers.strip_tags(html)).must_equal stripped
      end
    end
  end

  describe "#truncate" do
    it "should truncate the given text around a given length" do
      _(@helpers.truncate("Hello world", length: 5)).must_equal "Hello."
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

    it "escapes the link text and attributes" do
      _(@helpers.link_to("Bar < Foo", "qux", title: "Foo > Bar")).
        must_equal %(<a href="qux" title="Foo &gt; Bar">Bar &lt; Foo</a>)
    end

    it "returns the escaped text when URL argument is nil" do
      _(@helpers.link_to("Bar < Foo", nil, title: "Foo > Bar")).
        must_equal %(Bar &lt; Foo)
    end

    it "returns an appropriate link when URL argument is an RDoc::CodeObject that responds to #path" do
      top_level = rdoc_top_level_for <<~RUBY
        module Foo; class Bar; def qux; end; end; end
      RUBY

      _(@helpers.link_to("perma", top_level.find_module_named("Foo"))).
        must_equal %(<a href="/classes/Foo.html">perma</a>)

      _(@helpers.link_to("perma", top_level.find_module_named("Foo::Bar"))).
        must_equal %(<a href="/classes/Foo/Bar.html">perma</a>)

      _(@helpers.link_to("perma", top_level.find_module_named("Foo::Bar").find_method("qux", false))).
        must_equal %(<a href="/classes/Foo/Bar.html#method-i-qux">perma</a>)
    end
  end

  describe "#base_tag_for_context" do
    it "returns an idempotent <base> tag for the :index context" do
      _(@helpers.base_tag_for_context(:index)).
        must_equal %(<base href="./" data-current-path=".">)
    end

    it "returns a <base> tag with an appropriate path for the given RDoc::Context" do
      top_level = rdoc_top_level_for <<~RUBY
        module Foo; module Bar; module Qux; end; end; end
      RUBY

      _(@helpers.base_tag_for_context(top_level.find_module_named("Foo"))).
        must_equal %(<base href="../" data-current-path="classes/Foo.html">)

      _(@helpers.base_tag_for_context(top_level.find_module_named("Foo::Bar"))).
        must_equal %(<base href="../../" data-current-path="classes/Foo/Bar.html">)

      _(@helpers.base_tag_for_context(top_level.find_module_named("Foo::Bar::Qux"))).
        must_equal %(<base href="../../../" data-current-path="classes/Foo/Bar/Qux.html">)
    end
  end
end
