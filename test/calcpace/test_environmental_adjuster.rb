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
    # 20°C for 60 min: base 4.3 · (5/10)^1.5 = 1.52%
    result = @calc.calculate_penalty(temperature: 20, time_seconds: 3600)
    assert_equal 1.52, result[:factors][:heat]
    assert_equal 1.52, result[:total_penalty_percent]
  end

  def test_calculate_penalty_with_altitude
    # 1828.8m should have 3.76% penalty
    result = @calc.calculate_penalty(altitude: 1828.8)
    assert_equal 3.76, result[:factors][:altitude]
    assert_equal 3.76, result[:total_penalty_percent]
  end

  def test_calculate_penalty_combined
    # 20°C at 60m (1.52%) and 1828.8m (3.76%)
    result = @calc.calculate_penalty(temperature: 20, altitude: 1828.8, time_seconds: 3600)
    assert_equal 1.52, result[:factors][:heat]
    assert_equal 3.76, result[:factors][:altitude]
    assert_equal 5.28, result[:total_penalty_percent]
  end

  def test_adjust_time_with_no_penalties
    # 3600s (1h) at 15°C and 0m
    result = @calc.adjust_time(3600, temperature: 15, altitude: 0)
    assert_equal 3600, result[:original_time]
    assert_equal 3600, result[:adjusted_time]
    assert_equal 0.0, result[:penalty_percent]
  end

  def test_adjust_time_with_heat_and_altitude
    # 3600s at 20°C (Base 1.52% * 1.0x) and 1828.8m (3.76%) = 5.28% penalty
    # 3600 * 1.0528 = 3790.08
    result = @calc.adjust_time(3600, temperature: 20, altitude: 1828.8)
    assert_equal 3600, result[:original_time]
    assert_in_delta 3790.08, result[:adjusted_time], 0.01
    assert_equal 5.28, result[:penalty_percent]
    assert_equal '01:03:10', result[:adjusted_time_clock]
  end

  def test_calculate_penalty_with_fahrenheit
    # 68°F is 20°C. 20°C for 60m should have 1.52% penalty.
    result = @calc.calculate_penalty(temperature: 68, temperature_unit: :f, time_seconds: 3600)
    assert_equal 1.52, result[:factors][:heat]
    assert_equal 1.52, result[:total_penalty_percent]
  end

  def test_normalize_time_returns_original_for_ideal_conditions
    # 3600s in 15C/0m should normalize to 3600s
    result = @calc.normalize_time(3600, temperature: 15, altitude: 0)
    assert_equal 3600, result[:normalized_time]
  end

  def test_normalize_time_with_heat
    # If I ran 3600s at 20C (Base 1.52% penalty)
    # Duration factor for 60 min is 1.0x
    # Ideal time: 3600 / 1.0152 = 3546.10...
    result = @calc.normalize_time(3600, temperature: 20)
    assert_in_delta 3546.1, result[:normalized_time], 0.01
    assert_equal 1.52, result[:penalty_percent]
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
    # Factor: 1.76x (least-squares fit to El Helou et al. 2012, Table S3)
    # Penalty: 4.3 * 1.76 = 7.57%
    result = @calc.calculate_penalty(temperature: 25, time_seconds: 10_800)
    assert_equal 7.57, result[:factors][:heat]
  end

  def test_calculate_penalty_with_long_duration
    # 25C at 240 min (Amateur Marathon)
    # Factor: 2.81x
    # Penalty: 4.3 * 2.81 = 12.08%
    result = @calc.calculate_penalty(temperature: 25, time_seconds: 14_400)
    assert_equal 12.08, result[:factors][:heat]
  end

  # --- heat duration factor (fit to El Helou et al. 2012) ---

  def test_duration_factor_keeps_the_short_effort_points
    assert_in_delta 0.5, @calc.send(:duration_factor, 1200), 1e-12
    assert_in_delta 0.5, @calc.send(:duration_factor, 1800), 1e-12
    assert_in_delta 1.0, @calc.send(:duration_factor, 3600), 1e-12
  end

  def test_duration_factor_points_for_two_three_and_four_hours
    assert_in_delta 1.38, @calc.send(:duration_factor, 7200), 1e-12
    assert_in_delta 1.76, @calc.send(:duration_factor, 10_800), 1e-12
    assert_in_delta 2.285, @calc.send(:duration_factor, 12_600), 1e-12
    assert_in_delta 2.81, @calc.send(:duration_factor, 14_400), 1e-12
  end

  def test_duration_factor_is_flat_beyond_four_hours
    assert_in_delta 2.81, @calc.send(:duration_factor, 18_000), 1e-12
    assert_in_delta 2.81, @calc.send(:duration_factor, 36_000), 1e-12
  end

  # El Helou et al. (2012) PLoS One 7(5):e37407, Table S3: optimum °C, speed at
  # the optimum (m/s) and speed loss (%) at optimum −10, −5, 0, +5, +10, +15, +20 °C
  EL_HELOU_TABLE_S3 = {
    'men P1' => [3.81, 4.36, [1.41, 0.35, 0, 0.36, 1.44, 3.29, 6.00]],
    'men Q1' => [6.02, 3.32, [3.27, 0.82, 0, 0.82, 3.38, 7.93, 15.03]],
    'men median' => [6.24, 2.96, [3.77, 0.94, 0, 0.95, 3.91, 9.26, 17.73]],
    'men Q3' => [7.42, 2.62, [4.41, 1.10, 0, 1.12, 4.61, 11.01, 21.42]],
    'women P1' => [9.91, 3.78, [2.97, 0.74, 0, 0.75, 3.06, 7.16, 13.47]],
    'women Q1' => [6.85, 2.93, [2.51, 0.63, 0, 0.63, 2.58, 6.00, 11.18]],
    'women median' => [6.75, 2.65, [2.76, 0.69, 0, 0.70, 2.84, 6.63, 12.43]],
    'women Q3' => [7.35, 2.39, [3.04, 0.76, 0, 0.77, 3.14, 7.35, 13.85]]
  }.freeze

  # Reproduces the derivation documented in environmental_factors.yml, step 1:
  # the time penalty against 15 °C grows 2^p times from 20 to 25 °C in every
  # group; p is the sex-weighted mean of log2(P25 / P20), and the 60-minute
  # base follows 4.3 · ((T − 15) / 10)^p, anchored at base(25) = 4.3
  def test_heat_base_points_follow_the_el_helou_exponent
    exponent = el_helou_exponent
    assert_in_delta 1.497, exponent, 0.001

    points = EnvironmentalAdjuster::FACTORS.fetch('heat').fetch('data_points')
    points.each do |temperature, base|
      expected = (4.3 * (((temperature - 15) / 10.0)**exponent.round(2))).round(2)
      assert_in_delta expected, base, 1e-9, "#{temperature} °C"
    end
  end

  def test_heat_base_points_track_the_power_law_within_a_tenth
    exponent = el_helou_exponent.round(2)

    (1500..4000).each do |hundredths|
      temperature = hundredths / 100.0
      law = 4.3 * (((temperature - 15) / 10.0)**exponent)
      base = @calc.calculate_penalty(temperature: temperature, time_seconds: 3600)[:factors][:heat]

      assert_in_delta law, base, 0.1, "#{temperature} °C"
    end
  end

  # Step 2: those penalties divided by the base, fitted by weighted least
  # squares (each sex half the weight) with the 3 h and 4 h points free and
  # 1.0 at 60 min fixed
  def test_duration_factor_points_are_the_least_squares_fit_of_el_helou_table_s3
    observations = el_helou_ratios
    assert_equal 15, observations.size # men P1 at 25 °C lies beyond the table

    f180, f240 = weighted_two_point_fit(observations)
    points = EnvironmentalAdjuster::HEAT_DURATION_FACTORS.to_h

    assert_in_delta f180, points.fetch(180.0), 0.005
    assert_in_delta f240, points.fetch(240.0), 0.005
  end

  def test_duration_factor_is_continuous_and_monotonic
    factors = (0..21_600).step(30).map { |seconds| @calc.send(:duration_factor, seconds) }

    factors.each_cons(2) do |a, b|
      assert_operator b, :>=, a
      assert_operator b - a, :<, 0.02
    end
  end

  def test_extreme_heat_for_four_hours
    # 35 °C / 4 h: 12.16 * 2.81 = 34.17%; 40 °C / 4 h: 17.0 * 2.81 = 47.77% (extrapolated)
    assert_equal 34.17, @calc.calculate_penalty(temperature: 35, time_seconds: 14_400)[:factors][:heat]
    assert_equal 47.77, @calc.calculate_penalty(temperature: 40, time_seconds: 14_400)[:factors][:heat]
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

    assert_equal 7.9, at30
    assert_equal 12.16, at35
  end

  def test_heat_at_forty_is_worse_than_at_thirty_five
    assert_equal 17.0, @calc.calculate_penalty(temperature: 40, time_seconds: 3600)[:factors][:heat]
  end

  def test_heat_is_capped_at_forty
    assert_equal 17.0, @calc.calculate_penalty(temperature: 45, time_seconds: 3600)[:factors][:heat]
  end

  # --- humidity / dew point (effective temperature) ---

  def test_humidity_at_the_reference_reproduces_the_temperature_only_numbers
    [3600, 14_400].each do |seconds|
      plain = @calc.calculate_penalty(temperature: 30, time_seconds: seconds)
      humid = @calc.calculate_penalty(temperature: 30, humidity: 50, time_seconds: seconds)

      assert_equal plain[:factors][:heat], humid[:factors][:heat]
    end
  end

  def test_humidity_at_the_reference_is_exact_for_random_inputs
    rng = Random.new(20_261_002)

    5000.times do
      temperature = (rng.rand * 50) - 5
      seconds = rng.rand * 20_000
      plain = @calc.calculate_penalty(temperature: temperature, time_seconds: seconds)
      humid = @calc.calculate_penalty(temperature: temperature, humidity: 50, time_seconds: seconds)

      assert_equal plain[:total_penalty_percent], humid[:total_penalty_percent], "T=#{temperature} s=#{seconds}"
    end
  end

  def test_penalty_is_interpolated_on_the_unrounded_effective_temperature
    # 30.42271454 °C used to be rounded to 30.42 before interpolating
    plain = @calc.calculate_penalty(temperature: 30.42271454, time_seconds: 3600)
    humid = @calc.calculate_penalty(temperature: 30.42271454, humidity: 50, time_seconds: 3600)

    assert_equal plain[:factors][:heat], humid[:factors][:heat]
    assert_in_delta 30.42, humid[:factors][:effective_temperature_celsius], 0.0
  end

  def test_dew_point_below_minus_one_hundred_is_rejected
    assert_raises(ArgumentError) { @calc.calculate_penalty(temperature: 30, dew_point: -240) }
    assert_raises(ArgumentError) { @calc.calculate_penalty(temperature: 30, dew_point: -100.01) }
    assert_kind_of Hash, @calc.calculate_penalty(temperature: 30, dew_point: -100)
  end

  def test_complex_humidity_or_dew_point_is_rejected
    assert_raises(ArgumentError) { @calc.calculate_penalty(temperature: 30, humidity: Complex(80, 0)) }
    assert_raises(ArgumentError) { @calc.calculate_penalty(temperature: 30, dew_point: Complex(20, 0)) }
  end

  def test_non_finite_temperature_with_humidity_is_rejected
    [Float::NAN, Float::INFINITY, -Float::INFINITY].each do |temperature|
      assert_raises(ArgumentError) { @calc.calculate_penalty(temperature: temperature, humidity: 50) }
      assert_raises(ArgumentError) { @calc.calculate_penalty(temperature: temperature, dew_point: 10) }
    end
  end

  def test_reference_humidity_constant
    assert_in_delta 50.0, EnvironmentalAdjuster::REFERENCE_HUMIDITY, 0.0
  end

  def test_humid_air_raises_the_effective_temperature_and_the_penalty
    # WBGT(30 °C, 90%) = WBGT(35.94 °C, 50%) → base 12.16 + 0.94/2.5 × 2.35 = 13.04
    result = @calc.calculate_penalty(temperature: 30, humidity: 90, time_seconds: 3600)

    assert_in_delta 35.94, result[:factors][:effective_temperature_celsius], 0.01
    assert_equal 13.04, result[:factors][:heat]
    assert_equal 13.04, result[:total_penalty_percent]
  end

  def test_dry_air_lowers_the_effective_temperature_and_the_penalty
    # WBGT(30 °C, 30%) = WBGT(26.6946 °C, 50%) → base 4.3 + 1.6946/2.5 × 1.71 = 5.46
    result = @calc.calculate_penalty(temperature: 30, humidity: 30, time_seconds: 3600)

    assert_in_delta 26.69, result[:factors][:effective_temperature_celsius], 0.01
    assert_equal 5.46, result[:factors][:heat]
  end

  def test_humidity_scales_with_duration_like_temperature
    result = @calc.calculate_penalty(temperature: 30, humidity: 90, time_seconds: 7200)

    assert_equal (13.04 * @calc.send(:duration_factor, 7200)).round(2), result[:factors][:heat]
  end

  def test_humid_air_can_lift_an_ideal_temperature_out_of_the_ideal_range
    # 15 °C at 90% behaves like 18.3304 °C at 50% → 0.54 + 0.8304/2.5 × 0.98 = 0.87
    result = @calc.calculate_penalty(temperature: 15, humidity: 90, time_seconds: 3600)

    assert_in_delta 18.33, result[:factors][:effective_temperature_celsius], 0.01
    assert_equal 0.87, result[:factors][:heat]
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

    assert_equal 13.04, adjusted[:penalty_percent]
    assert_equal 13.04, normalized[:penalty_percent]
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

  private

  # [sex, finish minutes, temperature, time penalty (%) against 15 °C]
  def el_helou_penalties
    EL_HELOU_TABLE_S3.flat_map do |group, (optimum, speed, losses)|
      minutes = 42_195 / speed / 60
      loss15 = table_loss(optimum, losses, 15)
      [20, 25].filter_map do |temperature|
        loss = table_loss(optimum, losses, temperature)
        next unless loss

        [group.split.first, minutes, temperature, (((1 - (loss15 / 100)) / (1 - (loss / 100))) - 1) * 100]
      end
    end
  end

  def el_helou_exponent
    pairs = el_helou_penalties.group_by { |sex, minutes, *| [sex, minutes] }.values.select { |rows| rows.size == 2 }
    per_sex = pairs.map { |rows| rows.first.first }.tally
    pairs.sum do |(at20, at25)|
      Math.log2(at25.last / at20.last) / per_sex[at20.first] / per_sex.size
    end
  end

  def el_helou_ratios
    base = EnvironmentalAdjuster::FACTORS.fetch('heat').fetch('data_points')
    el_helou_penalties.map do |sex, minutes, temperature, penalty|
      [sex, minutes, penalty / base.fetch(temperature)]
    end
  end

  # Straight line between the published points; nil beyond them
  def table_loss(optimum, losses, temperature)
    xs = (-10..20).step(5).map { |delta| optimum + delta }
    index = xs.each_cons(2).find_index { |low, high| temperature.between?(low, high) }
    return nil unless index

    losses[index] + ((temperature - xs[index]) / 5.0 * (losses[index + 1] - losses[index]))
  end

  # factor(m) = c0 + c1·f180 + c2·f240 on the 60 → 180 → 240 min segments
  def segment_weights(minutes)
    if minutes <= 180
      w = (minutes - 60) / 120.0
      [1 - w, w, 0.0]
    elsif minutes <= 240
      w = (minutes - 180) / 60.0
      [0.0, 1 - w, w]
    else
      [0.0, 0.0, 1.0]
    end
  end

  def weighted_two_point_fit(observations)
    per_sex = observations.map(&:first).tally
    a11 = a12 = a22 = b1 = b2 = 0.0
    observations.each do |sex, minutes, ratio|
      weight = 1.0 / per_sex[sex]
      c0, c1, c2 = segment_weights(minutes)
      y = ratio - c0
      a11 += weight * c1 * c1
      a12 += weight * c1 * c2
      a22 += weight * c2 * c2
      b1 += weight * c1 * y
      b2 += weight * c2 * y
    end
    det = (a11 * a22) - (a12**2)
    [((b1 * a22) - (a12 * b2)) / det, ((a11 * b2) - (a12 * b1)) / det]
  end
end
