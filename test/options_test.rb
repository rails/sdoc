require "test_helper"

class OptionsTest < Test::Unit::TestCase
  def test_should_add_github_url_option
    o = Options.instance
    o.parse(%w(--github_url http://www.github.com), RDoc::RDoc::GENERATORS)
    assert_not_nil(o.github_url)
  end
  
  def test_should_add_github_path_option
    o = Options.instance
    o.parse(%w(--github_url .), RDoc::RDoc::GENERATORS)
    assert_not_nil(o.github_path)
  end
  
  def test_should_set_default_generator_to_shtml
    o = Options.instance
    o.parse(%w(--github_url http://www.github.com), RDoc::RDoc::GENERATORS)
    assert_equal('shtml', o.generator.key)
  end
  
  def test_should_set_default_template_to_shtml
    o = Options.instance
    o.parse(%w(--github_url http://www.github.com), RDoc::RDoc::GENERATORS)
    assert_equal('shtml', o.template)
  end
  
  def test_should_set_is_all_in_one_file_to_false
    o = Options.instance
    o.parse(%w(--one-file), RDoc::RDoc::GENERATORS)
    assert(!o.all_one_file, "Should not use all in one file")
  end
  
  def test_should_set_is_all_in_one_file_to_false_if_fmt_present
    o = Options.instance
    o.parse(%w(--one-file --fmt shtml), RDoc::RDoc::GENERATORS)
    assert(!o.all_one_file, "Should not use all in one file")
  end
end