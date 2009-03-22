Gem::Specification.new do |s| 
  s.name = "sdoc"
  s.version = "0.0.2"
  s.author = "Vladimir Kolesnikov"
  s.email = "voloko@gmail.com"
  s.homepage = "http://voloko.ru/sdoc/rails"
  s.platform = Gem::Platform::RUBY
  s.summary = "RDoc extensions for searchable html generations"
  s.files = %w(lib/sdoc/code_objects.rb lib/sdoc/generators/shtml_generator.rb lib/sdoc/generators/template/shtml/resources/css/master-frameset.css lib/sdoc/generators/template/shtml/resources/css/reset.css lib/sdoc/generators/template/shtml/resources/i/arrows.png lib/sdoc/generators/template/shtml/resources/i/results_bg.png lib/sdoc/generators/template/shtml/resources/i/tree_bg.png lib/sdoc/generators/template/shtml/resources/js/jquery-1.3.2.min.js lib/sdoc/generators/template/shtml/resources/js/searchdoc.js lib/sdoc/generators/template/shtml/resources/panel.html lib/sdoc/generators/template/shtml/shtml.rb lib/sdoc/options.rb lib/sdoc.rb bin/sdoc)
  s.executables = ['sdoc']
  s.bindir = 'bin'
  s.require_path = "lib"
  s.test_files = %w(test/options_test.rb test/sdoc_test.rb)
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
  s.add_dependency("json", ">= 1.1.3")
end
