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
require 'rails/api/task'

rails = File.expand_path "rails"
ruby = File.expand_path "ruby"

directory rails do
  sh "git clone --depth=1 https://github.com/rails/rails"
end

directory ruby do
  sh "git clone --depth=1 https://github.com/ruby/ruby"
end

class RailsTask < Rails::API::EdgeTask
  def configure_sdoc
    options << "--root" << "rails"
    super
    self.title = nil # Use default title for local testing.
  end

  def rails_version
    Dir.chdir "rails" do
      super
    end
  end

  def api_dir
    "doc/rails"
  end

  def component_root_dir(component)
    File.join("rails", component)
  end

  def setup_horo_variables
    super

    ENV["HORO_BADGE_VERSION"] ||= "edge" if ENV["HORO_PROJECT_VERSION"]&.include?("@")

    if ENV['NETLIFY']
      ENV['HORO_CANONICAL_URL'] = ENV.fetch('DEPLOY_PRIME_URL', 'https://edgeapi.rubyonrails.org')
    end
  end
end

namespace :test do
  desc 'Deletes all generated test documentation'
  task :reset_docs do
    FileUtils.remove_dir(File.expand_path('doc'), force: true)
  end

  desc 'Generates test rails documentation'
  task :rails => [rails, :generate_rails] do
    FileUtils.mv(
      File.expand_path('rails/doc/rails'),
      File.expand_path('doc/public')
    )
  end

  RailsTask.new(:generate_rails)

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

desc "Download and vendor JavaScript assets"
task :vendor_javascript do
  module Importmap; end
  require "importmap/packager"

  packager = Importmap::Packager.new(vendor_path: "#{ASSETS_PATH}/js")
  imports = packager.import("@hotwired/turbo", from: "unpkg")
  imports.each do |package, url|
    puts %(Vendoring "#{package}" to #{packager.vendor_path}/#{package}.js via download from #{url})
    packager.download(package, url)
  end
end
