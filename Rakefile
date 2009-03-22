require 'rake/testtask'
require 'rake/gempackagetask'

task :default => :test

Rake::TestTask.new("test") do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = true
  t.verbose = true
end
