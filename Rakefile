require 'rubygems'

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "spec/*_spec.rb"
end

task :default => :test
task :spec => :test

task :rdoc_master do
  if ENV["rdoc"]="master"
    puts "Testing against rdoc master, please wait for install.."
    sh "git clone --depth=1 https://github.com/rdoc/rdoc"
    cd "rdoc" do
      sh "rake"
      sh "rake install_gem"
    end
  else
    puts "Testing against bundled rdoc.."
  end
end
