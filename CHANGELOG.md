2.0.3
=====

* Use @options.title for the index

2.0.2
=====

* Remove accidental rack inclusion in gemspec

2.0.1
=====

* #142 Fix arrow icons for selected panel items
* #141 Always use only one metatag for keywords
* #140 Use h2 instead of h1 for banner header

2.0.0
=====

* #137 Replace frames based implementation with a css
* #132 Deprecate safe_level of ERB.new in Ruby 2.6

1.1.0
=====

* #138 - Fix panel header overflow on Chrome
* 39e6cae9 - Display version using `-v` or `--version` flags

1.0.0
=====

* #110 - Strip out HTML tags from search results description
* #109 - Add basic SEO tags
* #108 - Tiny refresh of the Rails theme
* e6f02b91 - Remove the jQuery effect library
* 73ace366 - Remove the `--without-search` option
* b1d429f2 - Produce HTML 5 output
* 38d06095 - Support only RDoc 5 and up
* #96 - Require at least Ruby 1.9.3

0.4.2
=====

[Compare v0.4.1...v0.4.2](https://github.com/voloko/sdoc/compare/v0.4.1...v0.4.2)

0.4.1
=====

[Compare v0.4.0...v0.4.1](https://github.com/voloko/sdoc/compare/v0.4.0...v0.4.1)

Breaking Changes
----------------

None.

Enhancements
------------

- 65e46cb2 Unordered lists inside ordered ones render ordered
- SDoc::VERSION
  - 2fe1a7b8 Move version to separate file, remove require_relative from gemspec
  - 97e1eda8 Push ./lib to $LOAD_PATH for require SDoc::VERSION
  - ad0a7e1e Initialize SDoc namespace in main file

Bug Fixes
---------

- 926ff732 Remove redundany < 5.0 from rdoc dependency specification
- db99e402 Remove code tags styling under pre elements
- a1d7e211 Follow up of #68
- bffc93ef Relax JSON dependency to ~> 1.7, >= 1.7.7
- 404dceb9 GH-72: Extra `<p>` tags appear in results snippet

0.4.0
=====

[Compare v0.3.20...v0.4.0](https://github.com/voloko/sdoc/compare/v0.3.20...v0.4.0)

No friendly log for this version yet, but PRs are welcome!

