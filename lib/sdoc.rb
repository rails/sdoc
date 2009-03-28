$:.unshift File.dirname(__FILE__)
$:.unshift File.join File.dirname(__FILE__), '..', 'rdoc', 'lib'
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

