begin
  gem 'rdoc', '>= 5.0'
  require File.join(File.dirname(__FILE__), '/../sdoc')
rescue Gem::LoadError
end
