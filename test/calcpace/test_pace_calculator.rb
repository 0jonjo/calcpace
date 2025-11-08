# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/calcpace'

# Test race pace calculator functionality
class TestPaceCalculator < Minitest::Test
  def setup
    @calc = Calcpace.new
  end

  def test_list_races
    races = @calc.list_races
    assert_kind_of Hash, races
    assert_equal 4, races.size
    assert_equal 5.0, races['5k']
    assert_equal 10.0, races['10k']
    assert_equal 21.0975, races['half_marathon']
    assert_equal 42.195, races['marathon']
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
end
