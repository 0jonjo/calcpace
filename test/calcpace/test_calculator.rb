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
    assert_raises(RuntimeError) { @checker.velocity(0, 10) }
    assert_raises(RuntimeError) { @checker.velocity(10, -1) }
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
    assert_raises(RuntimeError) { @checker.pace(0, 10) }
    assert_raises(RuntimeError) { @checker.pace(10, -1) }
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
    assert_raises(RuntimeError) { @checker.time(0, 10) }
    assert_raises(RuntimeError) { @checker.time(10, -1) }
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
    assert_raises(RuntimeError) { @checker.distance(0, 10) }
    assert_raises(RuntimeError) { @checker.distance(10, -1) }
  end

  def test_checked_distance
    assert_raises(RuntimeError) { @checker.checked_distance('', '00:05:00') }
    assert_raises(RuntimeError) { @checker.checked_distance('01:00:00', '') }
    assert_equal 18.0, @checker.checked_distance('01:30:00', '00:05:00')
    assert_equal 15.493, @checker.checked_distance('01:37:21', '00:06:17').round(3)
  end

  def test_readme_examples_one
    assert_equal 3.386206896551724, @checker.velocity(3625, 12_275)
    assert_equal 305.4166666666667, @checker.pace(3665, 12)
    assert_equal 2520.0, @checker.time(210, 12)
    assert_equal 80.5, @checker.distance(9660, 120)
  end

  def test_readme_examples_two
    assert_equal 2.8658333333333332, @checker.checked_velocity('01:00:00', 10_317)
    assert_equal '00:00:02', @checker.clock_velocity('01:00:00', 10_317)
    assert_equal 489.2, @checker.checked_pace('01:21:32', 10)
    assert_equal '00:08:09', @checker.clock_pace('01:21:32', 10)
    assert_equal 4170.599999999999, @checker.checked_time('00:05:31', 12.6)
    assert_equal '01:09:30', @checker.clock_time('00:05:31', 12.6)
    assert_equal 12.640826873385013, @checker.checked_distance('01:21:32', '00:06:27')
  end
end
