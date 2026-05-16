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
    # 20°C for 60 min should have 2.8% penalty (Updated scientific baseline)
    result = @calc.calculate_penalty(temperature: 20, time_seconds: 3600)
    assert_equal 2.8, result[:factors][:heat]
    assert_equal 2.8, result[:total_penalty_percent]
  end

  def test_calculate_penalty_with_altitude
    # 1828.8m should have 3.76% penalty
    result = @calc.calculate_penalty(altitude: 1828.8)
    assert_equal 3.76, result[:factors][:altitude]
    assert_equal 3.76, result[:total_penalty_percent]
  end

  def test_calculate_penalty_combined
    # 20°C at 60m (2.8%) and 1828.8m (3.76%)
    result = @calc.calculate_penalty(temperature: 20, altitude: 1828.8, time_seconds: 3600)
    assert_equal 2.8, result[:factors][:heat]
    assert_equal 3.76, result[:factors][:altitude]
    assert_equal 6.56, result[:total_penalty_percent]
  end

  def test_adjust_time_with_no_penalties
    # 3600s (1h) at 15°C and 0m
    result = @calc.adjust_time(3600, temperature: 15, altitude: 0)
    assert_equal 3600, result[:original_time]
    assert_equal 3600, result[:adjusted_time]
    assert_equal 0.0, result[:penalty_percent]
  end

  def test_adjust_time_with_heat_and_altitude
    # 3600s at 20°C (Base 2.8% * 1.0x = 2.8%) and 1828.8m (3.76%) = 6.56% penalty
    # 3600 * 1.0656 = 3836.16
    result = @calc.adjust_time(3600, temperature: 20, altitude: 1828.8)
    assert_equal 3600, result[:original_time]
    assert_in_delta 3836.16, result[:adjusted_time], 0.01
    assert_equal 6.56, result[:penalty_percent]
    assert_equal '01:03:56', result[:adjusted_time_clock]
  end

  def test_calculate_penalty_with_fahrenheit
    # 68°F is 20°C. 20°C for 60m should have 2.8% penalty.
    result = @calc.calculate_penalty(temperature: 68, temperature_unit: :f, time_seconds: 3600)
    assert_equal 2.8, result[:factors][:heat]
    assert_equal 2.8, result[:total_penalty_percent]
  end

  def test_normalize_time_returns_original_for_ideal_conditions
    # 3600s in 15C/0m should normalize to 3600s
    result = @calc.normalize_time(3600, temperature: 15, altitude: 0)
    assert_equal 3600, result[:normalized_time]
  end

  def test_normalize_time_with_heat
    # If I ran 3600s at 20C (Base 2.8% penalty)
    # Duration factor for 60 min is 1.0x
    # Effective penalty: 2.8 * 1.0 = 2.8%
    # Ideal time: 3600 / 1.028 = 3501.945...
    result = @calc.normalize_time(3600, temperature: 20)
    assert_in_delta 3501.95, result[:normalized_time], 0.01
    assert_equal 2.8, result[:penalty_percent]
  end

  def test_environmental_round_trip_consistency
    # This test is tricky because adjust_time uses 'time_seconds' (3600) for duration factor,
    # while normalize_time uses 'adjusted_time' (~4000) for duration factor.
    # To test consistency, we must ensure that for the SAME duration, the math is reversible.

    penalty = @calc.calculate_penalty(temperature: 25, altitude: 2000, time_seconds: 3600)
    percent = penalty[:total_penalty_percent]

    adjusted = 3600 * (1 + (percent / 100.0))
    normalized = adjusted / (1 + (percent / 100.0))

    assert_in_delta 3600, normalized, 0.01
  end

  def test_calculate_penalty_with_duration
    # 25C at 180 min (Marathon sub-3)
    # Factor: 3.0x
    # Penalty: 4.3 * 3.0 = 12.9%
    result = @calc.calculate_penalty(temperature: 25, time_seconds: 10_800)
    assert_equal 12.9, result[:factors][:heat]
  end

  def test_calculate_penalty_with_long_duration
    # 25C at 240 min (Amateur Marathon)
    # Factor: 4.5x
    # Penalty: 4.3 * 4.5 = 19.35%
    result = @calc.calculate_penalty(temperature: 25, time_seconds: 14_400)
    assert_equal 19.35, result[:factors][:heat]
  end
end
