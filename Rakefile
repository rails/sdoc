require 'rubygems'

require 'bundler'
Bundler::GemHelper.install_tasks

gem 'rspec', '>= 2.5.0'
require 'rspec/core/rake_task'

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec)
task :default => :spec
task :test => :spec
