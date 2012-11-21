# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "sdoc"
  s.version = "0.3.20"

  s.authors = ["Vladimir Kolesnikov", "Nathan Broadbent"]
  s.description = %q{rdoc generator html with javascript search index.}
  s.summary = %q{rdoc html with javascript search index.}
  s.homepage = %q{http://github.com/voloko/sdoc}
  s.email = %q{voloko@gmail.com}

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if
    s.respond_to? :required_rubygems_version=

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = ["README.md"]

  s.add_runtime_dependency('rdoc', "~> 3.10")
  if defined?(JRUBY_VERSION)
    s.platform = Gem::Platform.new(['universal', 'java', nil])
    s.add_runtime_dependency("json_pure", ">= 1.1.3")
  else
    s.add_runtime_dependency("json", ">= 1.1.3")
  end

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
end

