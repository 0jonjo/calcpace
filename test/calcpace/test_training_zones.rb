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
end
