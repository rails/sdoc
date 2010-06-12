require 'rubygems'
if Gem.available? "yajl-ruby"
  gem "yajl-ruby", ">= 0.7.6"
  require "yajl"
else
  if Gem.available? "json" 
    gem "json", ">= 1.1.3"
  else
    gem "json_pure", ">= 1.1.3"
  end
  require "json"
end
