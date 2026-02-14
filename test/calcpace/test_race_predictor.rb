# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/calcpace'

# Test race predictor functionality using Riegel formula
class TestRacePredictor < Minitest::Test
  def setup
    @calc = Calcpace.new
  end

  # Test basic predictions
  def test_predict_time_5k_to_10k
    # 5K in 20:00 should predict roughly 41:30-42:00 for 10K
    result = @calc.predict_time('5k', '00:20:00', '10k')

    # Expected: 1200 * (10/5)^1.06 ≈ 1200 * 2.0844 ≈ 2501 seconds ≈ 41:41
    assert_in_delta 2501, result, 10
  end

  def test_predict_time_5k_to_marathon
    # 5K in 20:00 should predict roughly 3:11-3:12 for marathon
    result = @calc.predict_time('5k', '00:20:00', 'marathon')

    # Expected: 1200 * (42.195/5)^1.06 ≈ 11,509 seconds ≈ 3:11:49
    assert_in_delta 11_509, result, 100
  end

  def test_predict_time_10k_to_half_marathon
    # 10K in 42:00 should predict roughly 1:32:40 for half marathon
    result = @calc.predict_time('10k', '00:42:00', 'half_marathon')

    # Expected: 2520 * (21.0975/10)^1.06 ≈ 5,560 seconds ≈ 1:32:40
    assert_in_delta 5_560, result, 50
  end

  def test_predict_time_half_marathon_to_marathon
    # Half marathon in 1:30:00 should predict roughly 3:08-3:10 for marathon
    result = @calc.predict_time('half_marathon', '01:30:00', 'marathon')

    # Expected: 5400 * (42.195/21.0975)^1.06 ≈ 11,318 seconds ≈ 3:08:38
    assert_in_delta 11_318, result, 100
  end

  def test_predict_time_marathon_to_5k
    # Reverse prediction: marathon in 3:30:00 to 5K
    result = @calc.predict_time('marathon', '03:30:00', '5k')

    # Should be faster pace for shorter distance
    assert result < 1500, "5K time should be under 25:00 for a 3:30 marathoner"
    assert_in_delta 1314, result, 30 # Roughly 21:54
  end

  def test_predict_time_with_numeric_input
    # Test with numeric seconds input
    result = @calc.predict_time('5k', 1200, '10k')

    assert_in_delta 2501, result, 10
  end

  def test_predict_time_with_mile_distances
    # Test with mile-based distances
    result = @calc.predict_time('1mile', '00:06:00', '5mile')

    # Should scale appropriately
    assert result > 1800, "5 mile time should be more than 30:00"
    assert result < 2400, "5 mile time should be less than 40:00"
  end

  # Test clock format output
  def test_predict_time_clock_5k_to_marathon
    result = @calc.predict_time_clock('5k', '00:20:00', 'marathon')

    # Should return HH:MM:SS format
    assert_match(/^\d{2}:\d{2}:\d{2}$/, result)

    # Should be around 3:11:49
    time_parts = result.split(':').map(&:to_i)
    assert_equal 3, time_parts[0], "Should be 3 hours"
    assert_in_delta 12, time_parts[1], 2, "Should be around 11-12 minutes"
  end

  def test_predict_time_clock_10k_to_half
    result = @calc.predict_time_clock('10k', '00:40:00', 'half_marathon')

    assert_match(/^\d{2}:\d{2}:\d{2}$/, result)
  end

  # Test pace predictions
  def test_predict_pace_5k_to_marathon
    result = @calc.predict_pace('5k', '00:20:00', 'marathon')

    # 5K pace is 4:00/km, marathon pace should be slower (around 4:24/km)
    assert result > 240, "Marathon pace should be slower than 5K pace"
    assert_in_delta 264, result, 10 # Roughly 4:24/km
  end

  def test_predict_pace_marathon_to_5k
    result = @calc.predict_pace('marathon', '03:30:00', '5k')

    # Marathon pace is 4:58/km, 5K pace should be faster (around 4:13/km)
    marathon_pace = 12_600 / 42.195 # ~298s/km
    assert result < marathon_pace, "5K pace should be faster than marathon pace"
    assert_in_delta 253, result, 10 # Roughly 4:13/km
  end

  def test_predict_pace_clock
    result = @calc.predict_pace_clock('5k', '00:20:00', 'marathon')

    # Should return MM:SS format
    assert_match(/^\d{2}:\d{2}:\d{2}$/, result)
  end

  # Test equivalent performance
  def test_equivalent_performance_structure
    result = @calc.equivalent_performance('10k', '00:42:00', '5k')

    assert_kind_of Hash, result
    assert_includes result, :time
    assert_includes result, :time_clock
    assert_includes result, :pace
    assert_includes result, :pace_clock
  end

  def test_equivalent_performance_values
    result = @calc.equivalent_performance('10k', '00:42:00', '5k')

    # 10K in 42:00 (4:12/km) should be equivalent to roughly 20:09 5K
    assert_in_delta 1209, result[:time], 30
    assert_match(/00:20:\d{2}/, result[:time_clock])
    assert_kind_of Float, result[:pace]
    assert_match(/00:04:\d{2}/, result[:pace_clock])
  end

  # Test error handling
  def test_predict_time_same_distance
    error = assert_raises(ArgumentError) do
      @calc.predict_time('5k', '00:20:00', '5k')
    end
    assert_match(/must be different/, error.message)
  end

  def test_predict_time_invalid_from_race
    assert_raises(ArgumentError) do
      @calc.predict_time('invalid', '00:20:00', '10k')
    end
  end

  def test_predict_time_invalid_to_race
    assert_raises(ArgumentError) do
      @calc.predict_time('5k', '00:20:00', 'invalid')
    end
  end

  def test_predict_time_negative_time
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.predict_time('5k', -1200, '10k')
    end
  end

  def test_predict_time_zero_time
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.predict_time('5k', 0, '10k')
    end
  end

  # Test edge cases
  def test_predict_very_short_to_very_long
    # 1 mile to marathon
    result = @calc.predict_time('1mile', '00:05:00', 'marathon')

    # Should be a reasonable marathon time
    assert result > 7200, "Marathon should be over 2 hours"
    assert result < 18_000, "Marathon should be under 5 hours"
  end

  def test_predict_very_long_to_very_short
    # Marathon to 1 mile
    result = @calc.predict_time('marathon', '04:00:00', '1mile')

    # Should be a reasonable mile time
    assert result > 240, "Mile should be over 4 minutes"
    assert result < 600, "Mile should be under 10 minutes"
  end

  def test_predict_with_string_time_format_mmss
    # Test with MM:SS format
    result = @calc.predict_time('5k', '20:00', '10k')

    assert_in_delta 2501, result, 10
  end

  # Test realistic scenarios
  def test_beginner_runner_prediction
    # Beginner: 5K in 30:00 to marathon
    result = @calc.predict_time_clock('5k', '00:30:00', 'marathon')

    time_seconds = @calc.convert_to_seconds(result)
    # Should predict around 4:20-4:40
    assert time_seconds > 15_000, "Should be over 4:10"
    assert time_seconds < 18_000, "Should be under 5:00"
  end

  def test_advanced_runner_prediction
    # Advanced: 5K in 16:00 to marathon
    result = @calc.predict_time_clock('5k', '00:16:00', 'marathon')

    time_seconds = @calc.convert_to_seconds(result)
    # Should predict around 2:28-2:32
    assert time_seconds > 8700, "Should be over 2:25"
    assert time_seconds < 9300, "Should be under 2:35"
  end

  def test_consistency_both_directions
    # Test that predicting A→B and then B→A gives similar results
    time_5k = 1200 # 20:00
    predicted_10k = @calc.predict_time('5k', time_5k, '10k')
    back_to_5k = @calc.predict_time('10k', predicted_10k, '5k')

    # Should be very close to original (allowing small rounding differences)
    assert_in_delta time_5k, back_to_5k, 5
  end
end
