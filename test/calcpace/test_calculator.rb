# frozen_string_literal: true

require 'minitest/autorun'
require 'bigdecimal'
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
    assert_equal '00:07:54', @checker.pace('01:37:21', 12.3)
  end

  def test_pace_without_bigdecimal_precision
    assert_equal '00:07:54', @checker.pace('01:37:21', 12.3, false)
  end

  def test_pace_seconds
    assert_raises(RuntimeError) { @checker.pace_seconds('', 10) }
    assert_raises(RuntimeError) { @checker.pace_seconds('invalid', 10) }
    assert_raises(RuntimeError) { @checker.pace_seconds('00:00:00', 0) }
    assert_raises(RuntimeError) { @checker.pace_seconds('00:00:00', -1) }
    assert_equal BigDecimal('474.8780487804878'), @checker.pace_seconds('01:37:21', 12.3)
  end

  def test_pace_seconds_with_bigdecimal_precision
    assert_equal BigDecimal('0.474878048780487804878048780487804878049e3'), @checker.pace_seconds('01:37:21', 12.3, true)
  end

  def test_total_time
    assert_raises(RuntimeError) { @checker.total_time('', 10) }
    assert_raises(RuntimeError) { @checker.total_time('invalid', 10) }
    assert_raises(RuntimeError) { @checker.total_time('00:00:00', 0) }
    assert_raises(RuntimeError) { @checker.total_time('00:00:00', -1) }
    assert_equal '01:00:00', @checker.total_time('00:05:00', 12)
  end

  def test_total_time_seconds
    assert_raises(RuntimeError) { @checker.total_time_seconds('', 10) }
    assert_raises(RuntimeError) { @checker.total_time_seconds('invalid', 10) }
    assert_raises(RuntimeError) { @checker.total_time_seconds('00:00:00', 0) }
    assert_raises(RuntimeError) { @checker.total_time_seconds('00:00:00', -1) }
    assert_equal 3600, @checker.total_time_seconds('00:05:00', 12)
    assert_equal 71_844.3, @checker.total_time_seconds('01:37:21', 12.3)
  end

  def test_total_time_seconds_with_bigdecimal_precision
    assert_equal BigDecimal('0.718443e5'), @checker.total_time_seconds('01:37:21', 12.3, true)
  end

  def test_distance
    assert_raises(RuntimeError) { @checker.distance('', '00:05:00') }
    assert_raises(RuntimeError) { @checker.distance('01:00:00', '') }
    assert_equal 18.0, @checker.distance('01:30:00', '00:05:00')
    assert_equal 15.0, @checker.distance('01:37:21', '00:06:17')
  end

  def test_distance_with_bigdecimal_precision
    assert_equal BigDecimal('0.15493368700265251989389920424403183024e2'), @checker.distance('01:37:21', '00:06:17', true)
  end
end
