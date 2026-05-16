# frozen_string_literal: true

require 'test_helper'

class TestEnvironmentalAdjuster < CalcpaceTest
  def test_calculate_penalty_returns_zero_for_ideal_conditions
    # Ideal conditions: 15°C, 0m altitude
    result = @calc.calculate_penalty(temperature: 15, altitude: 0)
    assert_equal 0.0, result[:total_penalty_percent]
    assert_equal 0.0, result[:factors][:heat]
    assert_equal 0.0, result[:factors][:altitude]
  end

  def test_calculate_penalty_with_heat
    # 20°C should have 4.5% penalty (Updated from Ely 2007 refined baseline)
    result = @calc.calculate_penalty(temperature: 20)
    assert_equal 4.5, result[:factors][:heat]
    assert_equal 4.5, result[:total_penalty_percent]
  end

  def test_calculate_penalty_with_altitude
    # 1828.8m should have 3.76% penalty (Updated to match NCAA 32.7s for 14:30 5k)
    result = @calc.calculate_penalty(altitude: 1828.8)
    assert_equal 3.76, result[:factors][:altitude]
    assert_equal 3.76, result[:total_penalty_percent]
  end

  def test_calculate_penalty_combined
    # 20°C (4.5%) and 1828.8m (3.76%)
    result = @calc.calculate_penalty(temperature: 20, altitude: 1828.8)
    assert_equal 4.5, result[:factors][:heat]
    assert_equal 3.76, result[:factors][:altitude]
    assert_equal 8.26, result[:total_penalty_percent]
  end

  def test_adjust_time_with_no_penalties
    # 3600s (1h) at 15°C and 0m
    result = @calc.adjust_time(3600, temperature: 15, altitude: 0)
    assert_equal 3600, result[:original_time]
    assert_equal 3600, result[:adjusted_time]
    assert_equal 0.0, result[:penalty_percent]
  end

  def test_adjust_time_with_heat_and_altitude
    # 3600s at 20°C (4.5%) and 1828.8m (3.76%) = 8.26% penalty
    # 3600 * 1.0826 = 3897.36
    result = @calc.adjust_time(3600, temperature: 20, altitude: 1828.8)
    assert_equal 3600, result[:original_time]
    assert_in_delta 3897.36, result[:adjusted_time], 0.01
    assert_equal 8.26, result[:penalty_percent]
    assert_equal '01:04:57', result[:adjusted_time_clock]
  end

  def test_calculate_penalty_with_fahrenheit
    # 68°F is 20°C. 20°C should have 4.5% penalty.
    result = @calc.calculate_penalty(temperature: 68, temperature_unit: :f)
    assert_equal 4.5, result[:factors][:heat]
    assert_equal 4.5, result[:total_penalty_percent]
  end

  def test_normalize_time_returns_original_for_ideal_conditions
    # 3600s in 15C/0m should normalize to 3600s
    result = @calc.normalize_time(3600, temperature: 15, altitude: 0)
    assert_equal 3600, result[:normalized_time]
  end

  def test_normalize_time_with_heat
    # If I ran 3600s at 20C (4.5% penalty), my ideal time should be ~3444.98s
    # Calculation: 3600 / 1.045 = 3444.976...
    result = @calc.normalize_time(3600, temperature: 20)
    assert_in_delta 3444.98, result[:normalized_time], 0.01
    assert_equal 4.5, result[:penalty_percent]
  end

  def test_environmental_round_trip_consistency
    # Adjust 3600s for 25C and 2000m, then normalize back.
    # Result should be very close to 3600s.
    adjusted = @calc.adjust_time(3600, temperature: 25, altitude: 2000)
    normalized = @calc.normalize_time(adjusted[:adjusted_time], temperature: 25, altitude: 2000)

    assert_in_delta 3600, normalized[:normalized_time], 0.1
  end
end
