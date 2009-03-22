require "rake"

Gem::Specification.new do |s| 
  s.name = "sdoc"
  s.version = "0.0.1"
  s.author = "Vladimir Kolesnikov"
  s.email = "voloko@gmail.com"
  s.homepage = "http://voloko.ru/sdoc/rails"
  s.platform = Gem::Platform::RUBY
  s.summary = "RDoc extensions for searchable html generations"
  s.files = FileList["{lib,bin}/**/*"].to_a
  s.executables = ['sdoc']
  s.bindir = 'bin'
  s.require_path = "lib"
  s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
  s.add_dependency("json", ">= 1.1.3")
end
