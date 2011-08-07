$:.unshift File.dirname(__FILE__)
require "rubygems"
gem "rdoc", ">= 3.9.0"

module SDoc end
  
require 'sdoc/generator'

# unless defined? SDOC_FIXED_RDOC_OPTIONS
#   SDOC_FIXED_RDOC_OPTIONS = 1
#   class RDoc::Options
#     alias_method :rdoc_initialize, :initialize
#   
#     def initialize
#       rdoc_initialize
#       @generator = RDoc::Generator::SHtml
#     end
#   end
# end
