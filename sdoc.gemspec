# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'sdoc/version'

Gem::Specification.new do |s|
  s.name = "sdoc"
  s.version = SDoc::VERSION

  # Original authors are: ["Vladimir Kolesnikov", "Nathan Broadbent", "Jean Mertz", "Zachary Scott"]
  s.authors = ["Toshimaru"]
  s.description = %q{rdoc generator html with javascript search index.}
  s.summary = %q{rdoc html with javascript search index.}
  s.homepage = %q{https://github.com/toshimaru/sdoc}
  s.email = %q{me@toshimaru.net}
  s.license = 'MIT'

  s.require_path = 'lib'

  s.required_ruby_version = ">= 2.7"

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = ["README.md"]

  s.add_runtime_dependency "rdoc", ">= 5.0"
  s.add_runtime_dependency "nokogiri"
  s.add_runtime_dependency "rouge"

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
end
