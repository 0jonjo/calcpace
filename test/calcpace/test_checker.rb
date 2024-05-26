# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/calcpace'

class TestChecker < Minitest::Test
  def setup
    @checker = Calcpace.new
  end

  def test_check_digits_distance
    assert_raises(RuntimeError) { @checker.check_digits_distance(-1) }
    assert_raises(RuntimeError) { @checker.check_digits_distance(0) }
    assert_nil @checker.check_digits_distance(1)
  end

  def test_check_digits_time
    assert_raises(RuntimeError) { @checker.check_digits_time('') }
    assert_nil @checker.check_digits_time('00:00:00')
  end

  def test_check_digits
    assert_raises(RuntimeError) { @checker.check_digits('00:00:00', 0) }
    assert_raises(RuntimeError) { @checker.check_digits('', 1) }
    assert_nil @checker.check_digits('00:00:00', 1)
  end

  def test_convert
    assert_equal 6.21, @checker.convert(10, 'km')
    assert_equal 16.09, @checker.convert(10, 'mi')
  end
end
