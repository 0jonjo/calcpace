# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/calcpace'

class TestChecker < Minitest::Test
  def setup
    @checker = Calcpace.new
  end

  def test_check_positive
    assert_raises(ArgumentError) { @checker.check_positive(-1) }
    assert_raises(ArgumentError) { @checker.check_positive(0) }
    assert_nil @checker.check_positive(1)
  end

  def test_check_time
    assert_raises(ArgumentError) { @checker.check_time('') }
    assert_nil @checker.check_time('00:00:00')
  end
end
