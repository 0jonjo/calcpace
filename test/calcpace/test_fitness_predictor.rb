# frozen_string_literal: true

require_relative '../test_helper'

# Tests for FitnessPredictor module — race times predicted from a VO2max value
class TestFitnessPredictor < CalcpaceTest
  # --- round-trip against the estimator it inverts ---
  def test_round_trip_reproduces_the_original_vo2max
    [[5.0, 50.0], [10.0, 45.0], [21.0975, 60.0], [42.195, 35.0], [1.60934, 70.0]].each do |distance, vo2max|
      seconds = @calc.predict_time_from_vo2max(vo2max, distance)

      assert_in_delta vo2max, @calc.estimate_vo2max(distance, seconds), 0.05,
                      "round trip failed for #{distance} km at VO2max #{vo2max}"
    end
  end

  def test_round_trip_for_race_names
    %w[5k 10k half_marathon marathon].each do |race|
      seconds = @calc.predict_time_from_vo2max(52.0, race)
      distance = @calc.list_races.fetch(race)

      assert_in_delta 52.0, @calc.estimate_vo2max(distance, seconds), 0.05, "round trip failed for #{race}"
    end
  end

  # --- sanity against Daniels' published VDOT table ---
  def test_vdot_fifty_matches_daniels_table
    # VDOT 50 → 5k 19:57, marathon 3:10:49 in Daniels' Running Formula
    assert_in_delta 1197, @calc.predict_time_from_vo2max(50, '5k'), 30
    assert_in_delta 11_449, @calc.predict_time_from_vo2max(50, 'marathon'), 300
  end

  def test_vdot_thirty_matches_daniels_table
    # VDOT 30 → 5k 30:40, marathon 4:49:17
    assert_in_delta 1840, @calc.predict_time_from_vo2max(30, '5k'), 60
    assert_in_delta 17_357, @calc.predict_time_from_vo2max(30, 'marathon'), 300
  end

  def test_vdot_seventy_matches_daniels_table
    # VDOT 70 → 5k 14:55, marathon 2:23:10
    assert_in_delta 895, @calc.predict_time_from_vo2max(70, '5k'), 30
    assert_in_delta 8590, @calc.predict_time_from_vo2max(70, 'marathon'), 300
  end

  # --- inputs ---
  def test_race_name_and_numeric_distance_agree
    assert_in_delta @calc.predict_time_from_vo2max(50, 10.0), @calc.predict_time_from_vo2max(50, '10k'), 0.5
  end

  def test_numeric_string_distance_is_read_as_kilometres
    assert_in_delta @calc.predict_time_from_vo2max(50, 10.0), @calc.predict_time_from_vo2max(50, '10'), 0.5
  end

  def test_race_name_accepts_symbols_and_padding
    assert_in_delta @calc.predict_time_from_vo2max(50, '10k'), @calc.predict_time_from_vo2max(50, :' 10K '), 0.5
  end

  def test_distance_unit_mi_converts_the_input_distance
    from_miles = @calc.predict_time_from_vo2max(50, 6.21371, distance_unit: :mi)

    assert_in_delta @calc.predict_time_from_vo2max(50, 10.0), from_miles, 1.0
  end

  def test_predict_time_from_vo2max_clock_formats_the_prediction
    seconds = @calc.predict_time_from_vo2max(50, '5k')

    assert_equal @calc.convert_to_clocktime(seconds), @calc.predict_time_from_vo2max_clock(50, '5k')
    assert_match(/\A\d{2}:\d{2}:\d{2}\z/, @calc.predict_time_from_vo2max_clock(50, '5k'))
  end

  # --- consistency ---
  def test_longer_races_take_longer_at_the_same_fitness
    times = %w[5k 10k half_marathon marathon].map { |race| @calc.predict_time_from_vo2max(50, race) }

    assert_equal times.sort, times
    assert_operator @calc.predict_time_from_vo2max(50, '5k'), :<, @calc.predict_time_from_vo2max(50, '10k')
  end

  def test_higher_vo2max_predicts_faster_times
    assert_operator @calc.predict_time_from_vo2max(60, '10k'), :<, @calc.predict_time_from_vo2max(45, '10k')
  end

  # --- race_times_from_vo2max ---
  def test_race_times_returns_the_four_default_races
    table = @calc.race_times_from_vo2max(50)

    assert_equal %w[5k 10k half_marathon marathon], table.keys
  end

  def test_race_times_entry_carries_time_and_pace_in_both_formats
    entry = @calc.race_times_from_vo2max(50)['5k']

    assert_equal %i[time time_clock pace pace_clock], entry.keys
    assert_in_delta @calc.predict_time_from_vo2max(50, '5k'), entry[:time], 0.5
    assert_in_delta entry[:time] / 5.0, entry[:pace], 0.01
    assert_equal @calc.convert_to_clocktime(entry[:time]), entry[:time_clock]
    assert_equal @calc.convert_to_clocktime(entry[:pace]), entry[:pace_clock]
  end

  def test_race_times_accepts_a_custom_race_list
    table = @calc.race_times_from_vo2max(50, races: %w[1mile 10mile 100k])

    assert_equal %w[1mile 10mile 100k], table.keys
    assert_operator table['1mile'][:time], :<, table['100k'][:time]
  end

  def test_race_times_paces_per_mile
    km_table = @calc.race_times_from_vo2max(50)
    mi_table = @calc.race_times_from_vo2max(50, races: %w[5k], unit: :mi)

    assert_in_delta km_table['5k'][:time], mi_table['5k'][:time], 0.5
    assert_in_delta km_table['5k'][:pace] * 1.609344, mi_table['5k'][:pace], 0.5
  end

  def test_race_times_rejects_an_unsupported_pace_unit
    assert_raises(Calcpace::UnsupportedUnitError) { @calc.race_times_from_vo2max(50, unit: :furlong) }
  end

  def test_race_times_rejects_an_unknown_race
    assert_error_with_message(ArgumentError, 'Unknown race') do
      @calc.race_times_from_vo2max(50, races: %w[5k ultra])
    end
  end

  # --- errors ---
  def test_rejects_non_positive_vo2max
    assert_raises(Calcpace::NonPositiveInputError) { @calc.predict_time_from_vo2max(0, '5k') }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.predict_time_from_vo2max(-10, '5k') }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.race_times_from_vo2max(0) }
  end

  def test_rejects_vo2max_outside_the_supported_range
    assert_error_with_message(ArgumentError, 'supported range') { @calc.predict_time_from_vo2max(0.1, '5k') }
    assert_error_with_message(ArgumentError, 'supported range') { @calc.predict_time_from_vo2max(200, 'marathon') }
  end

  def test_rejects_an_unknown_race_name
    assert_error_with_message(ArgumentError, 'Unknown race') { @calc.predict_time_from_vo2max(50, 'ultra') }
  end

  def test_rejects_non_positive_distance
    assert_raises(Calcpace::NonPositiveInputError) { @calc.predict_time_from_vo2max(50, 0) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.predict_time_from_vo2max(50, -5) }
  end

  def test_rejects_distance_unit_combined_with_a_race_name
    assert_error_with_message(ArgumentError, 'cannot be combined') do
      @calc.predict_time_from_vo2max(50, '10k', distance_unit: :mi)
    end
  end

  def test_rejects_an_unsupported_distance_unit
    assert_raises(Calcpace::UnsupportedUnitError) { @calc.predict_time_from_vo2max(50, 10, distance_unit: :furlong) }
  end
end
