require 'rake/testtask'
require 'rake/gempackagetask'

task :default => :test

Rake::TestTask.new("test") do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = true
  t.verbose = true
end

desc "Generate file list for .gemspec"
task :gem_file_list do
  f = FileList.new
  f.include('lib/**/**')
  f.include('rdoc/**/**')
  f.exclude('rdoc/test/**/**')
  print "%w(" + f.to_a.select{|file| !File.directory? file }.join(' ') + ")\n"
end

begin
  require 'jeweler'
  
  spec = Gem::Specification.new do |gem|
    gem.name = "sdoc"
    gem.summary = "rdoc html with javascript search index."
    gem.email = "voloko@gmail.com"
    gem.homepage = "http://github.com/voloko/sdoc"
    gem.authors = ["Volodya Kolesnikov"]
    gem.add_dependency("rdoc", ">= 2.4.2")
    
    if defined?(JRUBY_VERSION)
      gem.platform = Gem::Platform.new(['universal', 'java', nil])
      gem.add_dependency("json_pure", ">= 1.1.3")
    else
      gem.add_dependency("json", ">= 1.1.3")
    end    
  end
  
  jewler = Jeweler::Tasks.new(spec)

  desc "Replace system gem with symlink to this folder"
  task 'ghost' do
    path = Gem.searcher.find(jewler.gemspec.name).full_gem_path
    system 'sudo', 'rm', '-r', path
    symlink File.expand_path('.'), path
  end
rescue LoadError
  puts "Jeweler not available. Install it with: (sudo) gem install jeweler"
end
