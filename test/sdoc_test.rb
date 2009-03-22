require "test_helper"

class SDocTest < Test::Unit::TestCase
  def test_should_add_shtml_generator_to_generators_list
    assert(RDoc::RDoc::GENERATORS.has_key?('shtml'), "Should add shtml generator to list.")
  end
end