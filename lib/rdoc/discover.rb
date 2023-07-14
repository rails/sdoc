begin
  gem 'rdoc', '>= 5.0'
  require_relative "../sdoc" unless defined?(SDoc)
rescue Gem::LoadError
end
