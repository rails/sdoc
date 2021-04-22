require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "spec/*_spec.rb"
  t.libs << "spec"
end

task :default => :test
task :spec => :test

require 'sdoc'
require 'rdoc/task'

rails = File.expand_path "rails"

directory rails do
  sh "git clone --depth=1 https://github.com/rails/rails"
end

namespace :test do
  desc 'Deletes all generated test documentation'
  task :reset_docs do
    FileUtils.remove_dir(File.expand_path('doc'), force: true)
  end

  desc 'Generates test rails documentation'
  task :rails => [rails, :generate_rails] do
    FileUtils.mv(
      File.expand_path('doc/rails'),
      File.expand_path('doc/public')
    )
  end

  RDoc::Task.new(:generate_rails) do |rdoc|
    rdoc.rdoc_dir = 'doc/rails'
    rdoc.generator = 'sdoc'
    rdoc.template = 'rails'
    rdoc.title = 'Ruby on Rails'
    rdoc.main = 'rails/README.md'
    rdoc.options << '--exclude=test'

    rdoc.rdoc_files.include("rails/")
  end
end
