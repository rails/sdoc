# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'sdoc/version'

Gem::Specification.new do |s|
  s.name = "sdoc"
  s.version = SDoc::VERSION

  s.authors = ["Vladimir Kolesnikov", "Nathan Broadbent", "Jean Mertz", "Zachary Scott"]
  s.description = %q{rdoc generator html with javascript search index.}
  s.summary = %q{rdoc html with javascript search index.}
  s.homepage = %q{https://github.com/zzak/sdoc}
  s.email = %q{voloko@gmail.com mail@zzak.io}
  s.license = 'MIT'

  s.require_path = 'lib'

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if
    s.respond_to? :required_rubygems_version=

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = ["README.md"]

  s.add_runtime_dependency("rdoc", "~> 4.0")
  s.add_runtime_dependency("json", "~> 1.7", ">= 1.7.7")

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
end
