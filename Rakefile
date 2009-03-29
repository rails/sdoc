require 'rake/testtask'
require 'rake/gempackagetask'

task :default => :test

Rake::TestTask.new("test") do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = true
  t.verbose = true
end


task :gem_file_list do
  f = FileList.new
  f.include('lib/**/**')
  f.include('rdoc/**/**')
  f.exclude('rdoc/test/**/**')
  print "%w(" + f.to_a.select{|file| !File.directory? file }.join(' ') + ")"
end