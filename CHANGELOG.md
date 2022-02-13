Master
======

2.3.1
=====

* #183 Remove unsupported browser detection  [@p8](https://github.com/p8)
* #182 Use window.location instead of Turbolinks.visit if protocol is 'file:' [@p8](https://github.com/p8)

2.3.0
=====

* #178 Don't use rdoc 6.4.0 for now [@p8](https://github.com/p8)
* #177 Remove rake version constraint for ruby head [@p8](https://github.com/p8)
* #176 Make sidepanel work with relative paths/URLs [@p8](https://github.com/p8)
* #175 Avoid displaying source toggler for ghost methods [Robin Dupret](https://github.com/robin850)
* #174 Suppress unused variable warnings [Masataka Pocke Kuwabara](https://github.com/pocke)

2.2.0
=====

* #161 Add 'skip to content' link and improve shortcut keys [@MikeRogers0](https://github.com/MikeRogers0)
* #170 Fix link hovers in headings [@tlatsas](https://github.com/tlatsas)
* #169 Fix clearing search results [@mikdiet](https://github.com/mikdiet)
* #167 Update Merge script to work with sdoc v2 [@mikdiet](https://github.com/mikdiet)
* #160 Remove outline from reset stylesheet [@p8](https://github.com/p8)
* #159 Remove TAB override in panel [@p8](https://github.com/p8)
* #157 Move to GitHub action for tests [@MikeRogers0](https://github.com/MikeRogers0)
* #155 Fix Ctrl+C copying [Jan Schär](https://github.com/jscissr)

2.1.0
=====

* #154 Make panel responsive for mobile [@MikeRogers0](https://github.com/MikeRogers0) and [@p8](https://github.com/p8)
* #153 Add viewport metatag to views for improved Lighthouse score. [@MikeRogers0](https://github.com/MikeRogers0)
* #150 Use semantic headers for better SEO [@p8](https://github.com/p8)

2.0.4
=====

* #149 Using HTML5 doctype accross all HTML files. [@MikeRogers0](https://github.com/MikeRogers0)
* #148 Fix overflow CSS property of panel elements. [@cveneziani](https://github.com/cveneziani)

2.0.3
=====

* #147 Use @options.title for the index [@p8](https://github.com/p8)

2.0.2
=====

* Remove accidental rack inclusion in gemspec

2.0.1
=====

* #142 Fix arrow icons for selected panel items [@p8](https://github.com/p8)
* #141 Always use only one metatag for keywords [@p8](https://github.com/p8)
* #140 Use h2 instead of h1 for banner header [@p8](https://github.com/p8)

2.0.0
=====

* #137 Replace frames based implementation with a css [@p8](https://github.com/p8)
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
