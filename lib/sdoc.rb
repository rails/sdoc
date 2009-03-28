$:.unshift File.dirname(__FILE__)
$:.unshift File.join File.dirname(__FILE__), '..', 'rdoc', 'lib'
require "rdoc"

module SDoc
end

require "sdoc/generator/shtml"

