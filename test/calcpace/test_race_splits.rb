# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/calcpace'

# Test race splits functionality
class TestRaceSplits < Minitest::Test
  def setup
    @calc = Calcpace.new
  end

  # Test even pace splits
  def test_race_splits_half_marathon_5k
    # Half marathon (21.0975 km) in 1:30:00 with 5k splits
    result = @calc.race_splits('half_marathon', target_time: '01:30:00', split_distance: '5k')

    assert_equal 5, result.length # Should have 5 splits (5, 10, 15, 20, ~21.1)
    assert_equal '00:21:20', result[0] # First 5k
    assert_equal '00:42:40', result[1] # 10k
    # 10K in 40:00 with 1k splits
    result = @calc.race_splits('10k', target_time: '00:40:00', split_distance: '1k')

    assert_equal 10, result.length
    assert_equal '00:04:00', result[0] # First 1k (4:00/km pace)
    assert_equal '00:08:00', result[1] # 2k
    assert_equal '00:40:00', result[9] # Finish
  end

  def test_race_splits_5k_1k
    # 5K in 25:00 with 1k splits
    result = @calc.race_splits('5k', target_time: '00:25:00', split_distance: '1k')

    assert_equal 5, result.length
    assert_equal '00:05:00', result[0] # First 1k (5:00/km pace)
    assert_equal '00:25:00', result[4] # Finish
  end

  def test_race_splits_marathon_5k
    # Marathon in 3:30:00 with 5k splits
    result = @calc.race_splits('marathon', target_time: '03:30:00', split_distance: '5k')

    assert_equal 9, result.length # 9 splits for 42.195 km
    assert_equal '00:24:53', result[0] # First 5k
    assert_equal '03:30:00', result[8] # Finish
  end

  def test_race_splits_with_numeric_split
    # 10K with numeric split distance (2.5 km)
    result = @calc.race_splits('10k', target_time: '00:40:00', split_distance: 2.5)

    assert_equal 4, result.length
    assert_equal '00:10:00', result[0] # First 2.5k
    assert_equal '00:40:00', result[3] # Finish
  end

  def test_race_splits_with_mile_splits
    # 10K with mile splits
    result = @calc.race_splits('10k', target_time: '00:40:00', split_distance: '1mile')

    assert_equal 7, result.length # ~6.2 miles in 10k
    first_mile_time = @calc.convert_to_seconds(result[0])
    # First mile should be around 6:26 (4:00/km * 1.60934)
    assert_in_delta 386, first_mile_time, 5
  end

  # Test negative splits (second half faster)
  def test_race_splits_negative_10k
    result = @calc.race_splits('10k', target_time: '00:40:00', split_distance: '5k', strategy: :negative)

    assert_equal 2, result.length

    first_5k = @calc.convert_to_seconds(result[0])
    second_5k = @calc.convert_to_seconds(result[1]) - first_5k

    # First 5k should be slower than second 5k
    assert first_5k > second_5k, "First half (#{first_5k}s) should be slower than second half (#{second_5k}s)"

    # Total should still be 40:00
    assert_equal '00:40:00', result[1]
  end

  def test_race_splits_negative_half_marathon
    result = @calc.race_splits('half_marathon', target_time: '01:30:00', split_distance: '5k', strategy: :negative)

    # Find the halfway point (around split 2 or 3)
    halfway_idx = result.length / 2
    first_half_time = @calc.convert_to_seconds(result[halfway_idx])
    second_half_time = @calc.convert_to_seconds(result[-1]) - first_half_time

    # First half should be slower
    assert first_half_time > second_half_time
  end

  # Test positive splits (first half faster)
  def test_race_splits_positive_10k
    result = @calc.race_splits('10k', target_time: '00:40:00', split_distance: '5k', strategy: :positive)

    assert_equal 2, result.length

    first_5k = @calc.convert_to_seconds(result[0])
    second_5k = @calc.convert_to_seconds(result[1]) - first_5k

    # First 5k should be faster than second 5k
    assert first_5k < second_5k, "First half (#{first_5k}s) should be faster than second half (#{second_5k}s)"

    # Total should still be 40:00
    assert_equal '00:40:00', result[1]
  end

  # Test with string time format
  def test_race_splits_with_string_time
    result = @calc.race_splits('5k', target_time: '25:00', split_distance: '1k')

    assert_equal 5, result.length
    assert_equal '00:05:00', result[0]
  end

  # Test error handling
  def test_race_splits_invalid_race
    assert_raises(ArgumentError) do
      @calc.race_splits('invalid_race', target_time: '00:40:00', split_distance: '1k')
    end
  end

  def test_race_splits_zero_time
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.race_splits('10k', target_time: 0, split_distance: '1k')
    end
  end

  def test_race_splits_split_larger_than_race
    error = assert_raises(ArgumentError) do
      @calc.race_splits('5k', target_time: '00:25:00', split_distance: '10k')
    end
    assert_match(/cannot be greater than race distance/, error.message)
  end

  def test_race_splits_negative_split_distance
    error = assert_raises(ArgumentError) do
      @calc.race_splits('10k', target_time: '00:40:00', split_distance: -1)
    end
    assert_match(/must be positive/, error.message)
  end

  def test_race_splits_too_small_split_distance
    error = assert_raises(ArgumentError) do
      @calc.race_splits('marathon', target_time: '03:00:00', split_distance: 0.1)
    end
    assert_match(/too small/, error.message)
  end

  def test_race_splits_invalid_strategy
    error = assert_raises(ArgumentError) do
      @calc.race_splits('10k', target_time: '00:40:00', split_distance: '5k', strategy: :invalid)
    end
    assert_match(/Unknown strategy/, error.message)
  end

  def test_race_splits_invalid_split_format
    error = assert_raises(ArgumentError) do
      @calc.race_splits('10k', target_time: '00:40:00', split_distance: 'invalid')
    end
    assert_match(/Invalid split distance/, error.message)
  end

  # Test edge cases
  def test_race_splits_very_short_race
    # 1 mile race
    result = @calc.race_splits('1mile', target_time: '00:05:00', split_distance: '1mile')

    assert_equal 1, result.length
    assert_equal '00:05:00', result[0]
  end

  def test_race_splits_marathon_miles
    # Marathon with mile splits
    result = @calc.race_splits('marathon', target_time: '03:00:00', split_distance: '1mile')

    # Marathon is ~26.2 miles
    assert_equal 27, result.length
    assert_equal '03:00:00', result[-1]
  end

  def test_race_splits_5mile_1mile
    result = @calc.race_splits('5mile', target_time: '00:40:00', split_distance: '1mile')

    assert_equal 5, result.length
    assert_equal '00:08:00', result[0] # 8:00/mile pace
    assert_equal '00:40:00', result[4]
  end

  def test_race_splits_even_strategy_explicit
    # Explicitly test :even strategy
    result = @calc.race_splits('10k', target_time: '00:40:00', split_distance: '5k', strategy: :even)

    first_5k = @calc.convert_to_seconds(result[0])
    second_5k = @calc.convert_to_seconds(result[1]) - first_5k

    # Should be exactly the same (or within 1 second due to rounding)
    assert_in_delta first_5k, second_5k, 1
  end

  def test_race_splits_consistency
    # Make sure total always equals target time regardless of strategy
    strategies = %i[even negative positive]
    target = '00:40:00'

    strategies.each do |strategy|
      result = @calc.race_splits('10k', target_time: target, split_distance: '1k', strategy: strategy)
      assert_equal target, result[-1], "Final split should match target for #{strategy} strategy"
    end
  end
end
