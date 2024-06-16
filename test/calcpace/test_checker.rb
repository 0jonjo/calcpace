# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/calcpace'

class TestChecker < Minitest::Test
  def setup
    @checker = Calcpace.new
  end

  def test_check_distance
    assert_raises(RuntimeError) { @checker.check_distance(-1) }
    assert_raises(RuntimeError) { @checker.check_distance(0) }
    assert_nil @checker.check_distance(1)
  end

  def test_check_time
    assert_raises(RuntimeError) { @checker.check_time('') }
    assert_nil @checker.check_time('00:00:00')
  end

  def test_check_integer
    assert_raises(RuntimeError) { @checker.check_integer(-1) }
    assert_raises(RuntimeError) { @checker.check_integer(0) }
    assert_nil @checker.check_integer(1)
  end
end
