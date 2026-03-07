# frozen_string_literal: true

require_relative '../test_helper'

class TestCalculator < CalcpaceTest
  def test_velocity
    assert_equal 3.333, @calc.velocity(3600, 12_000).round(3)
    assert_equal 12.3, @calc.velocity(5841, 71_844.3)
    assert_equal 3.6, @calc.velocity(10_000, 36_000.0)
    assert_raises(Calcpace::NonPositiveInputError) { @calc.velocity(0, 10) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.velocity(10, -1) }
  end

  def test_checked_velocity
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.checked_velocity('', 10) }
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.checked_velocity('invalid', 10) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.checked_velocity('00:00:00', 0) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.checked_velocity('00:00:00', -1) }
    assert_equal 2.778, @calc.checked_velocity('01:00:00', 10_000).round(3)
    assert_equal 10, @calc.checked_velocity('00:00:01', 10)
    assert_equal 12.3, @calc.checked_velocity('01:37:21', 71_844.3)
  end

  def test_clock_velocity
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.clock_velocity('', 10) }
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.clock_velocity('invalid', 10) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.clock_velocity('00:00:00', 0) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.clock_velocity('00:00:00', -1) }
    assert_equal '00:00:02', @calc.clock_velocity('01:00:00', 10_000)
    assert_equal '00:00:12', @calc.clock_velocity('01:37:21', 71_844.3)
  end

  def test_pace
    assert_equal 300, @calc.pace(3600, 12)
    assert_equal 122.81076923076924, @calc.pace(71_844.3, 585.0)
    assert_raises(Calcpace::NonPositiveInputError) { @calc.pace(0, 10) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.pace(10, -1) }
  end

  def test_checked_pace
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.checked_pace('', 10) }
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.checked_pace('invalid', 10) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.checked_pace('00:00:00', 0) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.checked_pace('00:00:00', -1) }
    assert_equal 360, @calc.checked_pace('01:00:00', 10)
    assert_equal 474.8780487804878, @calc.checked_pace('01:37:21', 12.3)
  end

  def test_clock_pace
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.clock_pace('', 10) }
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.clock_pace('invalid', 10) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.clock_pace('00:00:00', 0) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.clock_pace('00:00:00', -1) }
    assert_equal '00:06:00', @calc.clock_pace('01:00:00', 10)
    assert_equal '00:07:54', @calc.clock_pace('01:37:21', 12.3)
  end

  def test_time
    assert_equal 43_200, @calc.time(3600, 12)
    assert_equal 5841.0, @calc.time(12.3, 474.8780487804878)
    assert_raises(Calcpace::NonPositiveInputError) { @calc.time(0, 10) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.time(10, -1) }
  end

  def test_checked_time
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.checked_time('', 10) }
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.checked_time('invalid', 10) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.checked_time('00:00:00', 0) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.checked_time('00:00:00', -1) }
    assert_equal 3600, @calc.checked_time('00:05:00', 12)
    assert_equal 71_844.3, @calc.checked_time('01:37:21', 12.3)
  end

  def test_clock_time
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.clock_time('', 10) }
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.clock_time('invalid', 10) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.clock_time('00:00:00', 0) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.clock_time('00:00:00', -1) }
    assert_equal '01:00:00', @calc.clock_time('00:05:00', 12)
  end

  def test_distance
    assert_equal 30, @calc.distance(3600, 120)
    assert_equal 12.3, @calc.distance(5841.0, 474.8780487804878)
    assert_raises(Calcpace::NonPositiveInputError) { @calc.distance(0, 10) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.distance(10, -1) }
  end

  def test_checked_distance
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.checked_distance('', '00:05:00') }
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.checked_distance('01:00:00', '') }
    assert_equal 18.0, @calc.checked_distance('01:30:00', '00:05:00')
    assert_equal 15.493, @calc.checked_distance('01:37:21', '00:06:17').round(3)
  end

  def test_readme_examples_one
    assert_equal 3.386206896551724, @calc.velocity(3625, 12_275)
    assert_equal 305.4166666666667, @calc.pace(3665, 12)
    assert_equal 2520.0, @calc.time(210, 12)
    assert_equal 80.5, @calc.distance(9660, 120)
  end

  def test_readme_examples_two
    assert_equal 2.8658333333333332, @calc.checked_velocity('01:00:00', 10_317)
    assert_equal '00:00:02', @calc.clock_velocity('01:00:00', 10_317)
    assert_equal 489.2, @calc.checked_pace('01:21:32', 10)
    assert_equal '00:08:09', @calc.clock_pace('01:21:32', 10)
    assert_equal 4170.599999999999, @calc.checked_time('00:05:31', 12.6)
    assert_equal '01:09:30', @calc.clock_time('00:05:31', 12.6)
    assert_equal 12.640826873385013, @calc.checked_distance('01:21:32', '00:06:27')
  end
end
