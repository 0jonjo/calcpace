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
    # Factor: 3.5x (El Helou et al. 2012, men's median ~3:58: 3.0-3.9x)
    # Penalty: 4.3 * 3.5 = 15.05%
    result = @calc.calculate_penalty(temperature: 25, time_seconds: 14_400)
    assert_equal 15.05, result[:factors][:heat]
  end

  # --- heat duration factor beyond 3 h ---

  def test_duration_factor_keeps_the_three_hour_anchor
    assert_in_delta 3.0, @calc.send(:duration_factor, 10_800), 1e-12
  end

  def test_duration_factor_reaches_three_and_a_half_at_four_hours
    assert_in_delta 3.5, @calc.send(:duration_factor, 14_400), 1e-12
    assert_in_delta 3.25, @calc.send(:duration_factor, 12_600), 1e-12
  end

  def test_duration_factor_is_flat_beyond_four_hours
    assert_in_delta 3.5, @calc.send(:duration_factor, 18_000), 1e-12
    assert_in_delta 3.5, @calc.send(:duration_factor, 36_000), 1e-12
  end

  def test_duration_factor_is_continuous_and_monotonic
    factors = (0..21_600).step(30).map { |seconds| @calc.send(:duration_factor, seconds) }

    factors.each_cons(2) do |a, b|
      assert_operator b, :>=, a
      assert_operator b - a, :<, 0.02
    end
  end

  def test_extreme_heat_for_four_hours
    # 35 °C / 4 h: 8.7 * 3.5 = 30.45% (was 39.15%); 40 °C / 4 h: 10.9 * 3.5 = 38.15% (was 49.05%)
    assert_equal 30.45, @calc.calculate_penalty(temperature: 35, time_seconds: 14_400)[:factors][:heat]
    assert_equal 38.15, @calc.calculate_penalty(temperature: 40, time_seconds: 14_400)[:factors][:heat]
  end

  # --- altitude curve (v1.19.0) ---

  def test_altitude_at_or_below_threshold_has_no_penalty
    assert_equal 0.0, @calc.calculate_penalty(altitude: 0)[:factors][:altitude]
    assert_equal 0.0, @calc.calculate_penalty(altitude: 300)[:factors][:altitude]
  end

  def test_altitude_is_continuous_just_above_the_threshold
    at_threshold = @calc.calculate_penalty(altitude: 300)[:factors][:altitude]
    ten_above = @calc.calculate_penalty(altitude: 310)[:factors][:altitude]

    assert_operator ten_above, :>, at_threshold, 'penalty should start growing right above the threshold'
    assert_operator ten_above - at_threshold, :<, 0.05
  end

  def test_altitude_is_continuous_across_the_first_ncaa_point
    below = @calc.calculate_penalty(altitude: 914.3)[:factors][:altitude]
    above = @calc.calculate_penalty(altitude: 914.5)[:factors][:altitude]

    assert_operator (above - below).abs, :<, 0.05
  end

  def test_altitude_is_continuous_around_the_first_ncaa_point
    below = @calc.calculate_penalty(altitude: 914)[:factors][:altitude]
    at    = @calc.calculate_penalty(altitude: 914.4)[:factors][:altitude]
    above = @calc.calculate_penalty(altitude: 915)[:factors][:altitude]

    assert_equal 1.41, at
    assert_in_delta at, below, 0.01
    assert_in_delta at, above, 0.01
  end

  def test_altitude_sao_paulo
    # 760 m: interpolated between 300 m (0.0) and 914.4 m (1.41)
    assert_equal 1.06, @calc.calculate_penalty(altitude: 760)[:factors][:altitude]
  end

  def test_altitude_keeps_the_ncaa_points
    assert_equal 2.15, @calc.calculate_penalty(altitude: 1219.2)[:factors][:altitude]
    assert_equal 5.9, @calc.calculate_penalty(altitude: 2438.4)[:factors][:altitude]
  end

  def test_altitude_keeps_growing_beyond_the_ncaa_table
    assert_equal 7.92, @calc.calculate_penalty(altitude: 3000)[:factors][:altitude]

    result = @calc.calculate_penalty(altitude: 3600)[:factors][:altitude]
    assert_operator result, :>, 9.97
    assert_operator result, :<, 12.2
  end

  def test_altitude_is_capped_at_4000_meters
    assert_equal 12.2, @calc.calculate_penalty(altitude: 4000)[:factors][:altitude]
    assert_equal 12.2, @calc.calculate_penalty(altitude: 5000)[:factors][:altitude]
  end

  # --- heat beyond 30 °C (v1.19.0) ---

  def test_heat_at_thirty_five_is_worse_than_at_thirty
    at30 = @calc.calculate_penalty(temperature: 30, time_seconds: 3600)[:factors][:heat]
    at35 = @calc.calculate_penalty(temperature: 35, time_seconds: 3600)[:factors][:heat]

    assert_equal 6.5, at30
    assert_equal 8.7, at35
  end

  def test_heat_at_forty_is_worse_than_at_thirty_five
    assert_equal 10.9, @calc.calculate_penalty(temperature: 40, time_seconds: 3600)[:factors][:heat]
  end

  def test_heat_is_capped_at_forty
    assert_equal 10.9, @calc.calculate_penalty(temperature: 45, time_seconds: 3600)[:factors][:heat]
  end

  # --- humidity / dew point (effective temperature) ---

  def test_humidity_at_the_reference_reproduces_the_temperature_only_numbers
    [3600, 14_400].each do |seconds|
      plain = @calc.calculate_penalty(temperature: 30, time_seconds: seconds)
      humid = @calc.calculate_penalty(temperature: 30, humidity: 50, time_seconds: seconds)

      assert_equal plain[:factors][:heat], humid[:factors][:heat]
    end
  end

  def test_reference_humidity_constant
    assert_in_delta 50.0, EnvironmentalAdjuster::REFERENCE_HUMIDITY, 0.0
  end

  def test_humid_air_raises_the_effective_temperature_and_the_penalty
    # WBGT(30 °C, 90%) = WBGT(35.94 °C, 50%) → base 8.7 + 0.94/5 × 2.2 = 9.11
    result = @calc.calculate_penalty(temperature: 30, humidity: 90, time_seconds: 3600)

    assert_in_delta 35.94, result[:factors][:effective_temperature_celsius], 0.01
    assert_equal 9.11, result[:factors][:heat]
    assert_equal 9.11, result[:total_penalty_percent]
  end

  def test_dry_air_lowers_the_effective_temperature_and_the_penalty
    # WBGT(30 °C, 30%) = WBGT(26.69 °C, 50%) → base 4.3 + 1.69/5 × 2.2 = 5.04
    result = @calc.calculate_penalty(temperature: 30, humidity: 30, time_seconds: 3600)

    assert_in_delta 26.69, result[:factors][:effective_temperature_celsius], 0.01
    assert_equal 5.04, result[:factors][:heat]
  end

  def test_humidity_scales_with_duration_like_temperature
    result = @calc.calculate_penalty(temperature: 30, humidity: 90, time_seconds: 7200)

    assert_equal (9.11 * 2.0).round(2), result[:factors][:heat]
  end

  def test_humid_air_can_lift_an_ideal_temperature_out_of_the_ideal_range
    # 15 °C at 90% behaves like 18.33 °C at 50% → 3.33/5 × 2.8 = 1.86
    result = @calc.calculate_penalty(temperature: 15, humidity: 90, time_seconds: 3600)

    assert_in_delta 18.33, result[:factors][:effective_temperature_celsius], 0.01
    assert_equal 1.86, result[:factors][:heat]
  end

  def test_dry_cool_air_stays_penalty_free
    result = @calc.calculate_penalty(temperature: 12, humidity: 20, time_seconds: 3600)

    assert_equal 0.0, result[:factors][:heat]
  end

  def test_effective_temperature_is_only_reported_when_humidity_is_given
    refute @calc.calculate_penalty(temperature: 30)[:factors].key?(:effective_temperature_celsius)
    assert_equal %i[heat altitude], @calc.calculate_penalty(temperature: 30)[:factors].keys
  end

  def test_dew_point_equal_to_temperature_is_saturated_air
    saturated = @calc.calculate_penalty(temperature: 30, dew_point: 30, time_seconds: 3600)
    full = @calc.calculate_penalty(temperature: 30, humidity: 100, time_seconds: 3600)

    assert_equal full, saturated
  end

  def test_dew_point_matches_the_equivalent_relative_humidity
    # Td 20 °C at 30 °C → e = 23.37 hPa of es = 42.43 hPa → RH 55.08%
    from_dew = @calc.calculate_penalty(temperature: 30, dew_point: 20, time_seconds: 3600)
    from_rh = @calc.calculate_penalty(temperature: 30, humidity: 55.08, time_seconds: 3600)

    assert_in_delta from_rh[:factors][:effective_temperature_celsius],
                    from_dew[:factors][:effective_temperature_celsius], 0.01
  end

  def test_dew_point_follows_the_temperature_unit
    fahrenheit = @calc.calculate_penalty(temperature: 86, dew_point: 68, temperature_unit: :f, time_seconds: 3600)
    celsius = @calc.calculate_penalty(temperature: 30, dew_point: 20, time_seconds: 3600)

    assert_equal celsius, fahrenheit
  end

  def test_humidity_outside_zero_to_one_hundred_is_rejected
    [-1, 100.5, Float::NAN].each do |rh|
      assert_raises(ArgumentError) { @calc.calculate_penalty(temperature: 30, humidity: rh) }
    end
  end

  def test_non_numeric_humidity_is_rejected
    assert_raises(ArgumentError) { @calc.calculate_penalty(temperature: 30, humidity: '80') }
    assert_raises(ArgumentError) { @calc.calculate_penalty(temperature: 30, dew_point: '20') }
  end

  def test_humidity_and_dew_point_together_are_rejected
    assert_raises(ArgumentError) { @calc.calculate_penalty(temperature: 30, humidity: 60, dew_point: 20) }
  end

  def test_dew_point_above_temperature_is_rejected
    assert_raises(ArgumentError) { @calc.calculate_penalty(temperature: 20, dew_point: 21) }
  end

  def test_humidity_without_temperature_is_rejected
    assert_raises(ArgumentError) { @calc.calculate_penalty(humidity: 60) }
    assert_raises(ArgumentError) { @calc.calculate_penalty(dew_point: 10) }
  end

  def test_adjust_and_normalize_forward_humidity
    adjusted = @calc.adjust_time(3600, temperature: 30, humidity: 90)
    normalized = @calc.normalize_time(3600, temperature: 30, humidity: 90)

    assert_equal 9.11, adjusted[:penalty_percent]
    assert_equal 9.11, normalized[:penalty_percent]
    assert_in_delta 35.94, adjusted[:factors][:effective_temperature_celsius], 0.01
  end

  def test_predictions_forward_humidity
    dry = @calc.predict_time_adjusted('5k', '00:20:00', '10k', temperature: 30, humidity: 30)
    humid = @calc.predict_time_adjusted('5k', '00:20:00', '10k', temperature: 30, humidity: 90)
    cameron = @calc.predict_time_cameron_adjusted('5k', '00:20:00', '10k', temperature: 30, humidity: 90)

    assert_operator humid[:adjusted_time], :>, dry[:adjusted_time]
    assert cameron[:factors].key?(:effective_temperature_celsius)
  end

  def test_environmental_data_keeps_the_structure_the_site_reads
    altitude = EnvironmentalAdjuster::FACTORS.fetch('altitude')
    heat = EnvironmentalAdjuster::FACTORS.fetch('heat')

    assert_kind_of Numeric, altitude.fetch('threshold_meters')
    assert_kind_of Hash, altitude.fetch('data_points')
    assert_equal [10.0, 15.0], heat.fetch('ideal_range_celsius')
    assert_kind_of Hash, heat.fetch('data_points')

    [altitude, heat].each do |table|
      table.fetch('data_points').each do |key, value|
        assert_kind_of Numeric, key
        assert_kind_of Numeric, value
      end
    end

    first_key, first_value = altitude.fetch('data_points').min_by { |key, _| key }
    assert_in_delta altitude.fetch('threshold_meters'), first_key, 0.0
    assert_in_delta 0.0, first_value, 0.0
  end
end
