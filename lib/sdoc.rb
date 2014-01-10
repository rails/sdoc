$:.unshift File.dirname(__FILE__)
require "rubygems"
gem 'rdoc'

module SDoc
  VERSION = "0.4.0"
end

require 'sdoc/generator'
