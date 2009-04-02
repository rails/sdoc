$:.unshift File.dirname(__FILE__)
require "rdoc/rdoc"

module SDoc
end

require "sdoc/generator/shtml"

class RDoc::Options
  alias_method :rdoc_initialize, :initialize
  
  def initialize
    rdoc_initialize
    @generator = RDoc::Generator::SHtml
  end
end

