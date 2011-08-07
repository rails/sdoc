begin
  gem 'rdoc', '~> 3'
  require File.join(File.dirname(__FILE__), '/../sdoc')
rescue Gem::LoadError
end
