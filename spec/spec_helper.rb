require 'rubygems'
require 'bundler/setup'

require 'sdoc'

require 'rdoc/test_case'

require 'minitest/autorun'

class SDoc::TestCase < RDoc::TestCase
  include MiniTest::Spec::DSL
end

