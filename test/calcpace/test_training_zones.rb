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
end
