# frozen_string_literal: true

require 'minitest/autorun'
require 'bigdecimal'
require_relative '../../lib/calcpace'

class TestCalculator < Minitest::Test
  def setup
    @checker = Calcpace.new
  end

  def test_velocity
    assert_equal 3.333, @checker.velocity(3600, 12_000).round(3)
    assert_equal 12.3, @checker.velocity(5841, 71_844.3)
    assert_equal 3.6, @checker.velocity(10_000, 36_000.0)
  end

  def test_checked_velocity
    assert_raises(RuntimeError) { @checker.checked_velocity('', 10) }
    assert_raises(RuntimeError) { @checker.checked_velocity('invalid', 10) }
    assert_raises(RuntimeError) { @checker.checked_velocity('00:00:00', 0) }
    assert_raises(RuntimeError) { @checker.checked_velocity('00:00:00', -1) }
    assert_equal 2.778, @checker.checked_velocity('01:00:00', 10_000).round(3)
    assert_equal 10, @checker.checked_velocity('00:00:01', 10)
    assert_equal 12.3, @checker.checked_velocity('01:37:21', 71_844.3)
  end

  def test_clock_velocity
    assert_raises(RuntimeError) { @checker.clock_velocity('', 10) }
    assert_raises(RuntimeError) { @checker.clock_velocity('invalid', 10) }
    assert_raises(RuntimeError) { @checker.clock_velocity('00:00:00', 0) }
    assert_raises(RuntimeError) { @checker.clock_velocity('00:00:00', -1) }
    assert_equal '00:00:02', @checker.clock_velocity('01:00:00', 10_000)
    assert_equal '00:00:12', @checker.clock_velocity('01:37:21', 71_844.3)
  end

  def test_pace
    assert_equal 300, @checker.pace(3600, 12)
    assert_equal 122.81076923076924, @checker.pace(71_844.3, 585.0)
  end

  def test_checked_pace
    assert_raises(RuntimeError) { @checker.checked_pace('', 10) }
    assert_raises(RuntimeError) { @checker.checked_pace('invalid', 10) }
    assert_raises(RuntimeError) { @checker.checked_pace('00:00:00', 0) }
    assert_raises(RuntimeError) { @checker.checked_pace('00:00:00', -1) }
    assert_equal 360, @checker.checked_pace('01:00:00', 10)
    assert_equal 474.8780487804878, @checker.checked_pace('01:37:21', 12.3)
  end

  def test_clock_pace
    assert_raises(RuntimeError) { @checker.clock_pace('', 10) }
    assert_raises(RuntimeError) { @checker.clock_pace('invalid', 10) }
    assert_raises(RuntimeError) { @checker.clock_pace('00:00:00', 0) }
    assert_raises(RuntimeError) { @checker.clock_pace('00:00:00', -1) }
    assert_equal '00:06:00', @checker.clock_pace('01:00:00', 10)
    assert_equal '00:07:54', @checker.clock_pace('01:37:21', 12.3)
  end

  def test_time
    assert_equal 43_200, @checker.time(3600, 12)
    assert_equal 5841.0, @checker.time(12.3, 474.8780487804878)
  end

  def test_checked_time
    assert_raises(RuntimeError) { @checker.checked_time('', 10) }
    assert_raises(RuntimeError) { @checker.checked_time('invalid', 10) }
    assert_raises(RuntimeError) { @checker.checked_time('00:00:00', 0) }
    assert_raises(RuntimeError) { @checker.checked_time('00:00:00', -1) }
    assert_equal 3600, @checker.checked_time('00:05:00', 12)
    assert_equal 71_844.3, @checker.checked_time('01:37:21', 12.3)
  end

  def test_clock_time
    assert_raises(RuntimeError) { @checker.clock_time('', 10) }
    assert_raises(RuntimeError) { @checker.clock_time('invalid', 10) }
    assert_raises(RuntimeError) { @checker.clock_time('00:00:00', 0) }
    assert_raises(RuntimeError) { @checker.clock_time('00:00:00', -1) }
    assert_equal '01:00:00', @checker.clock_time('00:05:00', 12)
  end

  def test_distance
    assert_equal 30, @checker.distance(3600, 120)
    assert_equal 12.3, @checker.distance(5841.0, 474.8780487804878)
  end

  def test_checked_distance
    assert_raises(RuntimeError) { @checker.checked_distance('', '00:05:00') }
    assert_raises(RuntimeError) { @checker.checked_distance('01:00:00', '') }
    assert_equal 18.0, @checker.checked_distance('01:30:00', '00:05:00')
    assert_equal 15.493, @checker.checked_distance('01:37:21', '00:06:17').round(3)
  end

  def test_readme_examples_1
    assert_equal 3.38697212, @checker.velocity(3623, 12_271).round(8)
    assert_equal 305.0, @checker.pace(3660, 12)
    assert_equal 43_920.0, @checker.time(3660, 12)
    assert_equal 30.5, @checker.distance(3660, 120)
  end

  def test_readme_examples_2
    assert_equal 0.5, @checker.checked_velocity('00:00:20', 10).round(3)
    assert_equal '00:00:02', @checker.clock_velocity('01:00:00', 10_317)
    assert_equal 489.2, @checker.checked_pace('01:21:32', 10)
    assert_equal '00:08:09', @checker.clock_pace('01:21:32', 10)
    assert_equal 4170.599999999999, @checker.checked_time('00:05:31', 12.6)
    assert_equal '01:09:30', @checker.clock_time('00:05:31', 12.6)
  end
end
