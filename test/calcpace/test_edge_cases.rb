# frozen_string_literal: true

require_relative '../test_helper'

# Test edge cases and boundary conditions
class TestEdgeCases < CalcpaceTest
  # Test very small values
  def test_velocity_with_small_values
    result = @calc.velocity(0.001, 0.001)
    assert_equal 1.0, result
  end

  def test_pace_with_small_values
    result = @calc.pace(0.001, 0.001)
    assert_equal 1.0, result
  end

  # Test very large values
  def test_velocity_with_large_values
    result = @calc.velocity(1_000_000, 1_000_000_000)
    assert_equal 1000.0, result
  end

  # Test single digit time formats
  def test_convert_to_seconds_single_digit_hour
    assert_equal 3661, @calc.convert_to_seconds('1:01:01')
  end

  def test_convert_to_seconds_single_digit_minute
    assert_equal 61, @calc.convert_to_seconds('1:01')
  end

  # Test boundary time values
  def test_convert_to_seconds_zero_time
    assert_equal 0, @calc.convert_to_seconds('0:00:00')
  end

  def test_convert_to_seconds_max_values
    assert_equal 359_999, @calc.convert_to_seconds('99:59:59')
  end

  # Test clocktime conversion for edge cases
  def test_convert_to_clocktime_zero
    assert_equal '00:00:00', @calc.convert_to_clocktime(0)
  end

  def test_convert_to_clocktime_exactly_one_day
    assert_equal '1 00:00:00', @calc.convert_to_clocktime(86_400)
  end

  def test_convert_to_clocktime_just_under_one_day
    assert_equal '23:59:59', @calc.convert_to_clocktime(86_399)
  end

  # Compact clocktime edge cases
  def test_convert_to_clocktime_compact_zero
    assert_equal '0:00', @calc.convert_to_clocktime(0, compact: true)
  end

  def test_convert_to_clocktime_compact_truncates_fractional_seconds
    # Same truncation as the padded format, which goes through Time.at
    assert_equal '00:04:52', @calc.convert_to_clocktime(292.9)
    assert_equal '4:52', @calc.convert_to_clocktime(292.9, compact: true)
  end

  def test_convert_to_clocktime_compact_accumulates_hours_beyond_a_day
    # The padded format prefixes a day count; the compact one keeps a single
    # running hour count, which is how ultra finish times are read
    assert_equal '24:00:00', @calc.convert_to_clocktime(86_400, compact: true)
    assert_equal '27:46:40', @calc.convert_to_clocktime(100_000, compact: true)
  end

  def test_convert_to_clocktime_rejects_negative_seconds
    assert_raises(Calcpace::NonPositiveInputError) { @calc.convert_to_clocktime(-5) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.convert_to_clocktime(-5, compact: true) }
  end

  # Test floating point precision
  def test_velocity_with_floats
    result = @calc.velocity(3.5, 10.5)
    assert_in_delta 3.0, result, 0.001
  end

  # Test conversion with decimal values
  def test_convert_with_decimal_values
    result = @calc.convert(1.5, :km_to_mi)
    assert_in_delta 0.932, result, 0.001
  end

  # Test that all conversion constants are accessible
  def test_all_distance_conversions_available
    distance_units = @calc.list_distance
    assert distance_units.size > 20, 'Expected at least 20 distance conversions'
    distance_units.each_key do |unit|
      assert @calc.constant(unit).positive?, "Constant for #{unit} should be positive"
    end
  end

  def test_all_speed_conversions_available
    speed_units = @calc.list_speed
    assert speed_units.size > 10, 'Expected at least 10 speed conversions'
    speed_units.each_key do |unit|
      assert @calc.constant(unit).positive?, "Constant for #{unit} should be positive"
    end
  end

  # Test string format variations
  def test_convert_with_string_various_formats
    assert_equal @calc.convert(1, :km_to_mi), @calc.convert(1, 'km to mi')
    assert_equal @calc.convert(1, :km_to_mi), @calc.convert(1, 'KM TO MI')
    assert_equal @calc.convert(1, :km_to_mi), @calc.convert(1, 'Km To Mi')
  end
end
