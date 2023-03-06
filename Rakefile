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
ruby = File.expand_path "ruby"

directory rails do
  sh "git clone --depth=1 https://github.com/rails/rails"
end

directory ruby do
  sh "git clone --depth=1 https://github.com/ruby/ruby"
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

  desc 'Generates test ruby documentation'
  task :ruby => [ruby, :generate_ruby] do
    FileUtils.mv(
      File.expand_path('doc/ruby'),
      File.expand_path('doc/public')
    )
  end

  RDoc::Task.new(:generate_ruby) do |rdoc|
    rdoc.rdoc_dir = 'doc/ruby'
    rdoc.generator = 'sdoc'
    rdoc.template = 'rails'
    rdoc.title = 'Ruby'
    rdoc.main = 'ruby/README.md'

    rdoc.rdoc_files.include("ruby/")
  end
end

ASSETS_PATH = "lib/rdoc/generator/template/rails/resources"

task :vendor_javascript do
  module Importmap; end
  require "importmap/packager"

  packager = Importmap::Packager.new(vendor_path: "#{ASSETS_PATH}/js")
  imports = packager.import("@hotwired/turbo", from: "unpkg")
  imports.each do |package, url|
    umd_url = url.gsub("esm.js", "umd.js")
    puts %(Vendoring "#{package}" to #{packager.vendor_path}/#{package}.js via download from #{umd_url})
    packager.download(package, umd_url)
  end
end