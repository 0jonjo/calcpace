# frozen_string_literal: true

require_relative '../test_helper'

# Tests for TrainingZones module — Daniels training paces and Karvonen HR zones
class TestTrainingZones < CalcpaceTest
  # --- training_paces ---
  def test_training_paces_returns_all_five_zones
    zones = @calc.training_paces(50.0)

    assert_equal %i[easy marathon threshold interval repetition], zones.keys
  end

  def test_threshold_fast_pace_matches_daniels_vdot_table
    zones = @calc.training_paces(50.0)

    # VDOT 50 → T-pace 04:15/km in Daniels' official table
    assert_in_delta 255, zones[:threshold].fast_seconds, 2
    assert_equal '00:04:15', zones[:threshold].fast_clock
  end

  def test_easy_band_for_vo2max_fifty
    zones = @calc.training_paces(50.0)

    assert_in_delta 352, zones[:easy].slow_seconds, 2 # ~05:52/km (59% VO2max)
    assert_in_delta 294, zones[:easy].fast_seconds, 2 # ~04:54/km (74% VO2max)
  end

  def test_interval_band_for_vo2max_fifty
    zones = @calc.training_paces(50.0)

    assert_in_delta 240, zones[:interval].slow_seconds, 2 # 95% → ~04:00/km
    assert_in_delta 230, zones[:interval].fast_seconds, 2 # 100% → ~03:50/km
  end

  def test_repetition_band_for_vo2max_fifty
    zones = @calc.training_paces(50.0)

    assert_in_delta 221, zones[:repetition].slow_seconds, 2 # 105% → ~03:41/km
    assert_in_delta 213, zones[:repetition].fast_seconds, 2 # 110% → ~03:33/km
  end

  def test_higher_vo2max_yields_faster_paces
    slower = @calc.training_paces(40.0)
    faster = @calc.training_paces(60.0)

    assert_operator faster[:easy].slow_seconds, :<, slower[:easy].slow_seconds
    assert_operator faster[:interval].fast_seconds, :<, slower[:interval].fast_seconds
  end

  def test_slow_is_always_slower_than_fast_within_each_band
    @calc.training_paces(50.0).each_value do |band|
      assert_operator band.slow_seconds, :>, band.fast_seconds
    end
  end

  def test_training_paces_rejects_non_positive_vo2max
    assert_raises(Calcpace::NonPositiveInputError) { @calc.training_paces(0) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.training_paces(-10) }
  end

  # --- training_paces in miles ---
  def test_training_paces_in_miles_scales_km_paces_by_mile_factor
    km = @calc.training_paces(50.0)
    mi = @calc.training_paces(50.0, unit: :mi)

    km.each_key do |zone|
      # Delta 2s: both paces are rounded independently, km rounding scales by 1.609
      assert_in_delta km[zone].fast_seconds * 1.609344, mi[zone].fast_seconds, 2
      assert_in_delta km[zone].slow_seconds * 1.609344, mi[zone].slow_seconds, 2
    end
  end

  def test_threshold_mile_pace_matches_daniels_vdot_table
    zones = @calc.training_paces(50.0, unit: :mi)

    # VDOT 50 → T-pace ~06:51/mile in Daniels' official table
    assert_in_delta 411, zones[:threshold].fast_seconds, 2
    assert_equal '00:06:51', zones[:threshold].fast_clock
  end

  def test_training_paces_default_unit_is_km
    assert_equal @calc.training_paces(50.0), @calc.training_paces(50.0, unit: :km)
  end

  def test_training_paces_rejects_unknown_unit
    error = assert_raises(Calcpace::UnsupportedUnitError) { @calc.training_paces(50.0, unit: :furlong) }
    assert_match(/km.*mi/i, error.message)
  end

  def test_training_paces_accepts_unit_in_any_case
    assert_equal @calc.training_paces(50.0, unit: :mi), @calc.training_paces(50.0, unit: 'MI')
  end

  def test_training_paces_rejects_nil_unit
    assert_raises(Calcpace::UnsupportedUnitError) { @calc.training_paces(50.0, unit: nil) }
  end

  # --- training_paces_from_race ---
  def test_training_paces_from_race_delegates_to_vo2max_estimation
    # 10k in 40:00 → VO2max 51.9 (value already validated in test_vo2max_estimator.rb)
    from_race = @calc.training_paces_from_race(10.0, '00:40:00')
    from_vo2  = @calc.training_paces(51.9)

    assert_equal from_vo2[:threshold].fast_seconds, from_race[:threshold].fast_seconds
    assert_equal from_vo2[:easy].slow_clock, from_race[:easy].slow_clock
  end

  def test_training_paces_from_race_accepts_seconds_input
    from_clock   = @calc.training_paces_from_race(10.0, '00:40:00')
    from_seconds = @calc.training_paces_from_race(10.0, 2400)

    assert_equal from_clock[:interval].fast_seconds, from_seconds[:interval].fast_seconds
  end

  def test_training_paces_from_race_accepts_unit
    from_race = @calc.training_paces_from_race(10.0, '00:40:00', unit: :mi)
    from_vo2  = @calc.training_paces(51.9, unit: :mi)

    assert_equal from_vo2[:threshold].fast_seconds, from_race[:threshold].fast_seconds
  end

  def test_training_paces_from_race_accepts_numeric_strings
    from_string = @calc.training_paces_from_race('10', '00:40:00')
    from_float  = @calc.training_paces_from_race(10.0, '00:40:00')

    assert_equal from_float, from_string
  end

  def test_training_paces_from_race_accepts_decimal_numeric_strings
    from_string = @calc.training_paces_from_race('21.0975', '01:30:00')
    from_float  = @calc.training_paces_from_race(21.0975, '01:30:00')

    assert_equal from_float, from_string
  end

  def test_training_paces_from_race_applies_distance_unit_to_numeric_strings
    from_string = @calc.training_paces_from_race('6.21371', '00:40:00', distance_unit: :mi)
    from_km     = @calc.training_paces_from_race(10.0, '00:40:00')

    assert_equal from_km, from_string
  end

  def test_training_paces_from_race_accepts_race_names
    from_name = @calc.training_paces_from_race('10k', '00:40:00')
    from_km   = @calc.training_paces_from_race(10.0, '00:40:00')

    assert_equal from_km[:threshold].fast_seconds, from_name[:threshold].fast_seconds
  end

  def test_training_paces_from_race_accepts_mile_race_names
    from_name = @calc.training_paces_from_race('5mile', '00:35:00')
    from_km   = @calc.training_paces_from_race(8.04672, '00:35:00')

    assert_equal from_km[:easy].slow_seconds, from_name[:easy].slow_seconds
  end

  def test_training_paces_from_race_rejects_distance_unit_with_race_name
    # A race name already carries its own distance, so a distance_unit alongside it
    # is always a caller mistake — say so instead of silently ignoring the keyword
    error = assert_raises(ArgumentError) do
      @calc.training_paces_from_race('10k', '00:40:00', distance_unit: :mi)
    end

    assert_match(/race name/i, error.message)
  end

  def test_mile_pace_unit_derives_from_the_canonical_mile
    assert_equal Converter::Distance::MI_TO_METERS, TrainingZones::PACE_UNIT_METERS[:mi]
  end

  def test_training_paces_from_race_rejects_unknown_race_name
    error = assert_raises(ArgumentError) { @calc.training_paces_from_race('parsec', '00:40:00') }
    assert_match(/unknown race/i, error.message)
  end

  def test_training_paces_from_race_propagates_input_errors
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.training_paces_from_race(0, '00:40:00')
    end
    assert_raises(Calcpace::InvalidTimeFormatError) do
      @calc.training_paces_from_race(10.0, 'banana')
    end
  end

  # --- hr_zones ---
  def test_hr_zones_returns_five_karvonen_zones
    zones = @calc.hr_zones(hr_max: 190, hr_rest: 55)

    assert_equal 5, zones.size
    assert_equal (1..5).to_a, zones.map(&:zone)
  end

  def test_hr_zones_karvonen_values
    zones = @calc.hr_zones(hr_max: 190, hr_rest: 55) # reserve = 135

    assert_equal 123, zones[0].min_bpm # 55 + 0.50*135 = 122.5 → 123
    assert_equal 136, zones[0].max_bpm # 55 + 0.60*135
    assert_equal 163, zones[3].min_bpm # 55 + 0.80*135
    assert_equal 177, zones[3].max_bpm # 55 + 0.90*135 = 176.5 → 177
    assert_equal 190, zones[4].max_bpm # Z5 ends at max heart rate
  end

  def test_hr_zones_are_contiguous
    zones = @calc.hr_zones(hr_max: 185, hr_rest: 60)

    zones.each_cons(2) do |prev, nxt|
      assert_equal prev.max_bpm, nxt.min_bpm
    end
  end

  def test_hr_zones_rejects_rest_greater_or_equal_to_max
    error = assert_raises(Calcpace::Error) { @calc.hr_zones(hr_max: 150, hr_rest: 150) }
    assert_match(/resting heart rate/i, error.message)
  end

  def test_hr_zones_rejects_non_positive_values
    assert_raises(Calcpace::NonPositiveInputError) { @calc.hr_zones(hr_max: 0, hr_rest: 55) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.hr_zones(hr_max: 190, hr_rest: -5) }
  end

  # --- hr_zones_from_max ---
  def test_hr_zones_from_max_returns_five_zones
    zones = @calc.hr_zones_from_max(hr_max: 190)

    assert_equal 5, zones.size
    assert_equal (1..5).to_a, zones.map(&:zone)
  end

  def test_hr_zones_from_max_percentage_values
    zones = @calc.hr_zones_from_max(hr_max: 190)

    assert_equal 95,  zones[0].min_bpm # 50% of 190
    assert_equal 114, zones[0].max_bpm # 60% of 190
    assert_equal 152, zones[3].min_bpm # 80% of 190
    assert_equal 171, zones[3].max_bpm # 90% of 190
    assert_equal 190, zones[4].max_bpm # Z5 ends at max heart rate
  end

  def test_hr_zones_from_max_are_contiguous
    @calc.hr_zones_from_max(hr_max: 185).each_cons(2) do |prev, nxt|
      assert_equal prev.max_bpm, nxt.min_bpm
    end
  end

  def test_hr_zones_from_max_is_more_conservative_than_karvonen
    from_max = @calc.hr_zones_from_max(hr_max: 190)
    karvonen = @calc.hr_zones(hr_max: 190, hr_rest: 55)

    # Without resting HR the lower bounds drop — expected from the %HRmax model
    assert_operator from_max[0].min_bpm, :<, karvonen[0].min_bpm
  end

  def test_hr_zones_from_max_rejects_non_positive
    assert_raises(Calcpace::NonPositiveInputError) { @calc.hr_zones_from_max(hr_max: 0) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.hr_zones_from_max(hr_max: -180) }
  end

  def test_training_paces_from_race_accepts_distance_in_miles
    mi = @calc.training_paces_from_race(6.21371, '00:40:00', distance_unit: :mi)
    km = @calc.training_paces_from_race(10.0, '00:40:00')

    assert_equal km[:threshold].fast_seconds, mi[:threshold].fast_seconds
  end

  # --- time_in_zones ---
  # Zones for hr_max 190: Z1 95–114, Z2 114–133, Z3 133–152, Z4 152–171, Z5 171–190
  def max_190_zones
    @calc.hr_zones_from_max(hr_max: 190)
  end

  def test_time_in_zones_documented_example
    in_zones = @calc.time_in_zones(heartrate: [120, 120, 140, 140, 160],
                                   time: [0, 60, 120, 180, 240],
                                   zones: max_190_zones)

    assert_equal [0, 120, 120, 60, 0], in_zones.map(&:seconds)
    assert_equal [0.0, 0.4, 0.4, 0.2, 0.0], in_zones.map(&:share)
  end

  def test_time_in_zones_returns_five_rows_in_zone_order
    in_zones = @calc.time_in_zones(heartrate: [160, 160], time: [0, 60], zones: max_190_zones)

    assert_equal 5, in_zones.size
    assert_equal [1, 2, 3, 4, 5], in_zones.map(&:zone)
  end

  def test_time_in_zones_returns_integer_seconds_and_float_shares
    in_zones = @calc.time_in_zones(heartrate: [120, 140], time: [0, 45], zones: max_190_zones)

    in_zones.each do |row|
      assert_kind_of Integer, row.seconds
      assert_kind_of Float, row.share
      assert_equal row.share.round(3), row.share
    end
  end

  # Rounded independently the five shares miss 1.0 by a thousandth or two, and a
  # bar chart drawn from them does not fill its track. Largest-remainder rounding
  # hands the residue to the zone that lost the most to rounding.
  def test_time_in_zones_shares_sum_to_exactly_one
    in_zones = @calc.time_in_zones(heartrate: [100, 125, 145, 165, 180],
                                   time: [0, 37, 71, 113, 150],
                                   zones: max_190_zones)

    assert_equal 1.0, in_zones.sum(&:share)
  end

  def test_time_in_zones_shares_sum_to_exactly_one_when_split_three_ways
    in_zones = @calc.time_in_zones(heartrate: [125, 145, 165], time: [0, 60, 120],
                                   zones: max_190_zones)

    assert_equal 1.0, in_zones.sum(&:share)
    assert_equal [0.0, 0.334, 0.333, 0.333, 0.0], in_zones.map(&:share)
  end

  def test_time_in_zones_leaves_shares_that_already_add_up_alone
    in_zones = @calc.time_in_zones(heartrate: [120, 120, 140, 140, 160],
                                   time: [0, 60, 120, 180, 240],
                                   zones: max_190_zones)

    assert_equal [0.0, 0.4, 0.4, 0.2, 0.0], in_zones.map(&:share)
    assert_equal 1.0, in_zones.sum(&:share)
  end

  # A sample lasts until the next one, so the last has no next: it inherits the
  # previous delta instead of being dropped.
  def test_time_in_zones_gives_the_last_sample_the_previous_delta
    in_zones = @calc.time_in_zones(heartrate: [150, 150], time: [0, 30], zones: max_190_zones)

    assert_equal 60, in_zones[2].seconds
    assert_equal 60, in_zones.sum(&:seconds)
  end

  def test_time_in_zones_counts_a_single_sample_as_zero_seconds
    in_zones = @calc.time_in_zones(heartrate: [150], time: [0], zones: max_190_zones)

    assert_equal [0, 0, 0, 0, 0], in_zones.map(&:seconds)
    assert_equal [0.0, 0.0, 0.0, 0.0, 0.0], in_zones.map(&:share)
  end

  def test_time_in_zones_returns_zero_rows_for_empty_series
    in_zones = @calc.time_in_zones(heartrate: [], time: [], zones: max_190_zones)

    assert_equal 5, in_zones.size
    assert_equal [0, 0, 0, 0, 0], in_zones.map(&:seconds)
    assert_equal [0.0, 0.0, 0.0, 0.0, 0.0], in_zones.map(&:share)
  end

  def test_time_in_zones_drops_samples_without_a_heart_rate
    in_zones = @calc.time_in_zones(heartrate: [120, nil, 120], time: [0, 60, 120], zones: max_190_zones)

    # The 60 s of the nil sample are dropped, not handed to a neighbour
    assert_equal 120, in_zones[1].seconds
    assert_equal 120, in_zones.sum(&:seconds)
  end

  def test_time_in_zones_drops_samples_with_a_non_positive_heart_rate
    in_zones = @calc.time_in_zones(heartrate: [120, 0, -5], time: [0, 60, 120], zones: max_190_zones)

    assert_equal 60, in_zones.sum(&:seconds)
    assert_equal 60, in_zones[1].seconds
  end

  def test_time_in_zones_gives_every_share_zero_when_nothing_is_counted
    in_zones = @calc.time_in_zones(heartrate: [nil, nil], time: [0, 60], zones: max_190_zones)

    assert_equal [0.0, 0.0, 0.0, 0.0, 0.0], in_zones.map(&:share)
  end

  def test_time_in_zones_counts_a_reading_below_zone_one_as_zone_one
    in_zones = @calc.time_in_zones(heartrate: [80, 80], time: [0, 60], zones: max_190_zones)

    assert_equal 120, in_zones[0].seconds
    assert_equal 1.0, in_zones[0].share
  end

  def test_time_in_zones_counts_a_reading_above_zone_five_as_zone_five
    in_zones = @calc.time_in_zones(heartrate: [205, 205], time: [0, 60], zones: max_190_zones)

    assert_equal 120, in_zones[4].seconds
    assert_equal 1.0, in_zones[4].share
  end

  def test_time_in_zones_puts_a_boundary_reading_in_the_higher_zone
    in_zones = @calc.time_in_zones(heartrate: [114, 114], time: [0, 60], zones: max_190_zones)

    assert_equal 120, in_zones[1].seconds
  end

  def test_time_in_zones_works_with_karvonen_zones_too
    in_zones = @calc.time_in_zones(heartrate: [150, 150], time: [0, 60],
                                   zones: @calc.hr_zones(hr_max: 190, hr_rest: 55))

    # Karvonen Z3 for 190/55 is 150–163
    assert_equal 120, in_zones[2].seconds
  end

  def test_time_in_zones_rejects_series_of_different_lengths
    assert_error_with_message(Calcpace::Error, 'same length') do
      @calc.time_in_zones(heartrate: [120, 130], time: [0, 60, 120], zones: max_190_zones)
    end
  end

  def test_time_in_zones_rejects_time_that_goes_backwards
    assert_error_with_message(Calcpace::Error, 'non-decreasing') do
      @calc.time_in_zones(heartrate: [120, 130, 140], time: [0, 120, 60], zones: max_190_zones)
    end
  end

  def test_time_in_zones_accepts_a_repeated_timestamp
    in_zones = @calc.time_in_zones(heartrate: [120, 120, 140], time: [0, 0, 60], zones: max_190_zones)

    assert_equal 60, in_zones[1].seconds
    assert_equal 60, in_zones[2].seconds
  end

  def test_time_in_zones_rejects_empty_zones
    assert_error_with_message(Calcpace::Error, 'zone') do
      @calc.time_in_zones(heartrate: [120], time: [0], zones: [])
    end
  end

  def test_time_in_zones_rejects_a_missing_heartrate_series
    assert_raises(Calcpace::Error) { @calc.time_in_zones(heartrate: nil, time: [0], zones: max_190_zones) }
  end

  def test_time_in_zones_rejects_a_missing_time_series
    assert_raises(Calcpace::Error) { @calc.time_in_zones(heartrate: [120], time: nil, zones: max_190_zones) }
  end

  # A gap in the time stream is not a zero-length sample — it is a stream we
  # cannot measure durations from at all
  def test_time_in_zones_rejects_a_nil_inside_the_time_series
    assert_error_with_message(Calcpace::Error, 'numeric') do
      @calc.time_in_zones(heartrate: [120, 130], time: [0, nil], zones: max_190_zones)
    end
  end

  # nil is a dropout; a String is a caller who has not parsed their stream
  def test_time_in_zones_rejects_a_heart_rate_that_is_not_a_number
    assert_error_with_message(Calcpace::Error, 'numeric') do
      @calc.time_in_zones(heartrate: [120, '130'], time: [0, 60], zones: max_190_zones)
    end
  end

  # --- hr_zone_for ---
  def test_hr_zone_for_returns_the_zone_holding_the_reading
    assert_equal 3, @calc.hr_zone_for(150, max_190_zones).zone
    assert_equal 133, @calc.hr_zone_for(150, max_190_zones).min_bpm
  end

  def test_hr_zone_for_gives_a_boundary_to_the_higher_zone
    # The site's own between? lookup gives 114 to zone 1; here it is zone 2
    assert_equal 2, @calc.hr_zone_for(114, max_190_zones).zone
    assert_equal 3, @calc.hr_zone_for(133, max_190_zones).zone
    assert_equal 5, @calc.hr_zone_for(171, max_190_zones).zone
  end

  def test_hr_zone_for_clamps_a_reading_below_zone_one
    assert_equal 1, @calc.hr_zone_for(80, max_190_zones).zone
  end

  # A reading above hr_max is a wrong hr_max, not a missing zone
  def test_hr_zone_for_clamps_a_reading_above_zone_five
    assert_equal 5, @calc.hr_zone_for(205, max_190_zones).zone
    assert_equal 5, @calc.hr_zone_for(190, max_190_zones).zone
  end

  def test_hr_zone_for_returns_nil_without_a_reading
    assert_nil @calc.hr_zone_for(nil, max_190_zones)
    assert_nil @calc.hr_zone_for(0, max_190_zones)
    assert_nil @calc.hr_zone_for(-5, max_190_zones)
  end

  def test_hr_zone_for_rejects_a_reading_that_is_not_a_number
    assert_error_with_message(Calcpace::Error, 'numeric') { @calc.hr_zone_for('150', max_190_zones) }
  end

  def test_hr_zone_for_rejects_empty_zones
    assert_error_with_message(Calcpace::Error, 'zone') { @calc.hr_zone_for(150, []) }
  end

  def test_hr_zone_for_works_with_karvonen_zones
    zones = @calc.hr_zones(hr_max: 190, hr_rest: 55)

    assert_equal 3, @calc.hr_zone_for(150, zones).zone
    assert_same zones[2], @calc.hr_zone_for(150, zones)
  end

  def test_time_in_zones_and_hr_zone_for_agree
    zones = max_190_zones

    [80, 114, 120, 133, 150, 171, 205].each do |bpm|
      in_zones = @calc.time_in_zones(heartrate: [bpm, bpm], time: [0, 60], zones: zones)
      counted = in_zones.find { |row| row.seconds.positive? }

      assert_equal @calc.hr_zone_for(bpm, zones).zone, counted.zone, "disagreed at #{bpm} bpm"
    end
  end
end
