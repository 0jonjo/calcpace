# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/calcpace'

class TestCalculator < Minitest::Test
  def setup
    @checker = Calcpace.new
  end

  def test_pace
    assert_raises(RuntimeError) { @checker.pace('', 10) }
    assert_raises(RuntimeError) { @checker.pace('invalid', 10) }
    assert_raises(RuntimeError) { @checker.pace('00:00:00', 0) }
    assert_raises(RuntimeError) { @checker.pace('00:00:00', -1) }
    assert_equal '00:06:00', @checker.pace('01:00:00', 10)
  end

  def test_total_time
    assert_raises(RuntimeError) { @checker.total_time('', 10) }
    assert_raises(RuntimeError) { @checker.total_time('invalid', 10) }
    assert_raises(RuntimeError) { @checker.total_time('00:00:00', 0) }
    assert_raises(RuntimeError) { @checker.total_time('00:00:00', -1) }
    assert_equal '01:00:00', @checker.total_time('00:05:00', 12)
  end

  def test_distance
    assert_raises(RuntimeError) { @checker.distance('', '00:05:00') }
    assert_raises(RuntimeError) { @checker.distance('01:00:00', '') }
    assert_equal 18.0, @checker.distance('01:30:00', '00:05:00')
  end
end
