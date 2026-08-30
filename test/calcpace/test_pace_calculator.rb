# frozen_string_literal: true

require_relative '../test_helper'

# Test race pace calculator functionality
class TestPaceCalculator < CalcpaceTest
  def test_list_races
    races = @calc.list_races
    assert_kind_of Hash, races
    assert_equal 8, races.size
    assert_equal 5.0, races['5k']
    assert_equal 10.0, races['10k']
    assert_equal 21.0975, races['half_marathon']
    assert_equal 42.195, races['marathon']
    assert_equal 100.0, races['100k']
    # Derived from the canonical international mile (1.609344 km)
    assert_equal 1.609344, races['1mile']
    assert_equal 8.04672, races['5mile']
    assert_equal 16.09344, races['10mile']
  end

  def test_race_lookup_tolerates_whitespace_and_case
    # 300 s/km over 10 km — same race, however the caller spells it
    assert_equal 3000.0, @calc.race_time(300, ' 10K ')
    assert_equal @calc.race_time(300, 'marathon'), @calc.race_time(300, :MARATHON)
  end

  def test_race_time_with_numeric_pace
    # 5:00/km pace for 5K should be 25:00 (1500 seconds)
    result = @calc.race_time(300, '5k')
    assert_equal 1500.0, result
  end

  def test_race_time_with_string_pace
    # 5:00/km pace for 10K should be 50:00 (3000 seconds)
    result = @calc.race_time('05:00', '10k')
    assert_equal 3000.0, result
  end

  def test_race_time_marathon
    # 5:00/km pace for marathon (42.195 km) should be ~3:30:58
    result = @calc.race_time(300, 'marathon')
    assert_in_delta 12_658.5, result, 0.5
  end

  def test_race_time_half_marathon
    # 5:00/km pace for half marathon (21.0975 km) should be ~1:45:17
    result = @calc.race_time(300, 'half_marathon')
    assert_in_delta 6329.25, result, 0.5
  end

  def test_race_time_100k
    # 6:00/km pace for 100k (360s/km) should be 10 hours (36000 seconds)
    result = @calc.race_time(360, '100k')
    assert_equal 36_000.0, result
  end

  def test_race_time_clock_format
    # 5:00/km pace for 5K should return "00:25:00"
    result = @calc.race_time_clock(300, '5k')
    assert_equal '00:25:00', result
  end

  def test_race_time_clock_marathon
    # 5:00/km pace for marathon should return ~"03:30:58"
    result = @calc.race_time_clock('05:00', 'marathon')
    assert_equal '03:30:58', result
  end

  def test_race_pace_numeric_target
    # To run 5K in 30:00 (1800 seconds), need 6:00/km (360 sec/km)
    result = @calc.race_pace(1800, '5k')
    assert_equal 360.0, result
  end

  def test_race_pace_string_target
    # To run 10K in 50:00, need 5:00/km (300 sec/km)
    result = @calc.race_pace('00:50:00', '10k')
    assert_equal 300.0, result
  end

  def test_race_pace_marathon
    # To run marathon in 3:30:00 (12600 seconds), need ~4:57/km
    result = @calc.race_pace('03:30:00', 'marathon')
    assert_in_delta 298.61, result, 1.0
  end

  def test_race_pace_100k
    # To run 100k in 10:00:00 (36000 seconds), need 6:00/km (360s/km)
    result = @calc.race_pace('10:00:00', '100k')
    assert_equal 360.0, result
  end

  def test_race_pace_clock_format
    # To run 5K in 30:00, need 6:00/km
    result = @calc.race_pace_clock(1800, '5k')
    assert_equal '00:06:00', result
  end

  def test_race_pace_clock_marathon
    # To run marathon in 4:00:00, need ~5:41/km
    result = @calc.race_pace_clock('04:00:00', 'marathon')
    assert_equal '00:05:41', result
  end

  def test_unknown_race_raises_error
    error = assert_raises(ArgumentError) do
      @calc.race_time(300, 'unknown_race')
    end
    assert_includes error.message, 'Unknown race'
    assert_includes error.message, 'unknown_race'
  end

  def test_negative_pace_raises_error
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.race_time(-300, '5k')
    end
  end

  def test_zero_pace_raises_error
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.race_time(0, 'marathon')
    end
  end

  def test_negative_target_time_raises_error
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.race_pace(-1800, '5k')
    end
  end

  # Practical examples
  def test_practical_example_sub_3_hour_marathon
    # What pace is needed for sub-3 hour marathon?
    pace = @calc.race_pace('02:59:59', 'marathon')
    # Sub-3 hour marathon requires pace around 4:15/km (255 sec/km)
    assert pace < 256, 'Should be faster than 4:16/km'
    assert pace > 253, 'Should be slower than 4:13/km'
  end

  def test_practical_example_sub_20_5k
    # What pace is needed for sub-20 minute 5K?
    pace = @calc.race_pace('00:19:59', '5k')
    time_string = @calc.race_pace_clock('00:19:59', '5k')
    assert pace < 240, 'Should be faster than 4:00/km'
    assert_match(/00:03:\d{2}/, time_string)
  end

  # --- free distances (v1.15.0) ---

  def test_race_time_accepts_a_numeric_distance
    # The everyday race with no standard name: 7.79 km at 5:00/km
    assert_in_delta 2337.0, @calc.race_time(300, 7.79), 0.001
  end

  def test_race_time_accepts_an_integer_distance
    assert_in_delta 3000.0, @calc.race_time(300, 10), 0.001
  end

  def test_race_time_accepts_a_numeric_string_distance
    # Same convention TrainingZones#training_paces_from_race and
    # FitnessPredictor already use: a numeric string is a distance, not a name
    assert_equal @calc.race_time(300, 7.79), @calc.race_time(300, '7.79')
  end

  def test_race_pace_accepts_a_numeric_distance
    assert_in_delta 231.065, @calc.race_pace(1800, 7.79), 0.001
  end

  def test_race_pace_clock_accepts_a_numeric_distance
    assert_equal '00:03:51', @calc.race_pace_clock('00:30:00', 7.79)
  end

  def test_numeric_distance_must_be_positive
    assert_raises(Calcpace::NonPositiveInputError) { @calc.race_time(300, 0) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.race_time(300, -7.79) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.race_pace(1800, '0') }
  end

  def test_non_numeric_race_names_still_raise_unknown_race
    error = assert_raises(ArgumentError) { @calc.race_time(300, '7.79k') }

    assert_includes error.message, 'Unknown race'
  end

  def test_numeric_distances_are_not_added_to_the_race_list
    assert_equal 8, @calc.list_races.size
    refute_includes @calc.list_races.keys, '7.79'
  end
end
