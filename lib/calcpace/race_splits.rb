# frozen_string_literal: true

# Module for calculating race splits (partial times)
#
# This module provides methods to calculate split times for races,
# supporting different pacing strategies like even pace, negative splits, etc.
module RaceSplits
  # Calculates split times for a race
  #
  # @param race [String, Symbol] race distance ('5k', '10k', 'half_marathon', 'marathon', etc.)
  # @param target_time [String] target finish time in HH:MM:SS or MM:SS format
  # @param split_distance [String, Numeric] distance for each split ('5k', '1k', '1mile', or numeric in km)
  # @param strategy [Symbol] pacing strategy - :even (default), :negative, or :positive
  # @return [Array<String>] array of cumulative split times in HH:MM:SS format
  # @raise [ArgumentError] if race or split_distance is invalid
  #
  # @example Even pace splits for half marathon
  #   race_splits('half_marathon', target_time: '01:30:00', split_distance: '5k')
  #   #=> ["00:21:18", "00:42:35", "01:03:53", "01:30:00"]
  #
  # @example Negative splits (second half faster)
  #   race_splits('10k', target_time: '00:40:00', split_distance: '5k', strategy: :negative)
  #   #=> ["00:20:48", "00:40:00"] (first 5k slower, second 5k faster)
  def race_splits(race, target_time:, split_distance:, strategy: :even)
    total_distance = race_distance(race)
    target_seconds = target_time.is_a?(String) ? convert_to_seconds(target_time) : target_time
    check_positive(target_seconds, 'Target time')

    split_km = normalize_split_distance(split_distance)
    validate_split_distance(split_km, total_distance)

    calculate_splits(total_distance, target_seconds, split_km, strategy)
  end

  private

  # Normalizes split distance to kilometers
  #
  # @param split_distance [String, Numeric] distance for each split
  # @return [Float] split distance in kilometers
  def normalize_split_distance(split_distance)
    if split_distance.is_a?(Numeric)
      split_distance.to_f
    elsif split_distance.is_a?(String)
      # Try to get from RACE_DISTANCES first (includes standard distances like '5k', '1mile', etc.)
      distance_key = split_distance.to_s.downcase

      # Check if it's a standard race distance
      begin
        return race_distance(distance_key)
      rescue ArgumentError
        # Not a race distance, try to parse as numeric
      end

      # Try to parse as number with optional 'k' or 'km'
      normalized = distance_key.gsub(/km?$/, '').strip
      begin
        Float(normalized)
      rescue StandardError
        raise(ArgumentError, "Invalid split distance: #{split_distance}")
      end
    else
      raise ArgumentError, "Split distance must be a number or string"
    end
  end

  # Validates that split distance is reasonable for the race
  #
  # @param split_km [Float] split distance in kilometers
  # @param total_distance [Float] total race distance in kilometers
  # @raise [ArgumentError] if split distance is invalid
  def validate_split_distance(split_km, total_distance)
    raise ArgumentError, "Split distance must be positive" if split_km <= 0

    if split_km > total_distance
      raise ArgumentError,
            "Split distance (#{split_km}km) cannot be greater than race distance (#{total_distance}km)"
    end

    # Allow some flexibility for non-exact divisions
    return unless (total_distance / split_km) > 100

    raise ArgumentError,
          "Split distance too small - would generate more than 100 splits"
  end

  # Calculates split times based on strategy
  #
  # @param total_distance [Float] total race distance in kilometers
  # @param target_seconds [Float] target finish time in seconds
  # @param split_km [Float] split distance in kilometers
  # @param strategy [Symbol] pacing strategy
  # @return [Array<String>] array of cumulative split times
  def calculate_splits(total_distance, target_seconds, split_km, strategy)
    case strategy
    when :even
      calculate_even_splits(total_distance, target_seconds, split_km)
    when :negative
      calculate_negative_splits(total_distance, target_seconds, split_km)
    when :positive
      calculate_positive_splits(total_distance, target_seconds, split_km)
    else
      raise ArgumentError,
            "Unknown strategy: #{strategy}. Supported strategies: :even, :negative, :positive"
    end
  end

  # Calculates even pace splits (constant pace throughout)
  #
  # @param total_distance [Float] total race distance in kilometers
  # @param target_seconds [Float] target finish time in seconds
  # @param split_km [Float] split distance in kilometers
  # @return [Array<String>] array of cumulative split times
  def calculate_even_splits(total_distance, target_seconds, split_km)
    pace_per_km = target_seconds / total_distance
    splits = []
    distance_covered = 0.0

    while distance_covered < total_distance - 0.001 # small tolerance for floating point
      distance_covered += split_km
      # Don't exceed total distance
      distance_covered = total_distance if distance_covered > total_distance

      split_time = (distance_covered * pace_per_km).round
      splits << convert_to_clocktime(split_time)
    end

    splits
  end

  # Calculates negative splits (second half faster than first half)
  # First half is ~4% slower, second half is ~4% faster
  #
  # @param total_distance [Float] total race distance in kilometers
  # @param target_seconds [Float] target finish time in seconds
  # @param split_km [Float] split distance in kilometers
  # @return [Array<String>] array of cumulative split times
  def calculate_negative_splits(total_distance, target_seconds, split_km)
    half_distance = total_distance / 2.0
    avg_pace = target_seconds / total_distance

    # First half: 4% slower, second half: 4% faster
    first_half_pace = avg_pace * 1.04
    second_half_pace = avg_pace * 0.96

    splits = []
    distance_covered = 0.0
    cumulative_time = 0.0

    while distance_covered < total_distance - 0.001
      distance_covered += split_km
      distance_covered = total_distance if distance_covered > total_distance

      if distance_covered <= half_distance
        # First half
        cumulative_time = distance_covered * first_half_pace
      else
        # Second half
        time_at_halfway = half_distance * first_half_pace
        distance_in_second_half = distance_covered - half_distance
        cumulative_time = time_at_halfway + (distance_in_second_half * second_half_pace)
      end

      splits << convert_to_clocktime(cumulative_time.round)
    end

    splits
  end

  # Calculates positive splits (first half faster than second half)
  # First half is ~4% faster, second half is ~4% slower
  #
  # @param total_distance [Float] total race distance in kilometers
  # @param target_seconds [Float] target finish time in seconds
  # @param split_km [Float] split distance in kilometers
  # @return [Array<String>] array of cumulative split times
  def calculate_positive_splits(total_distance, target_seconds, split_km)
    half_distance = total_distance / 2.0
    avg_pace = target_seconds / total_distance

    # First half: 4% faster, second half: 4% slower
    first_half_pace = avg_pace * 0.96
    second_half_pace = avg_pace * 1.04

    splits = []
    distance_covered = 0.0
    cumulative_time = 0.0

    while distance_covered < total_distance - 0.001
      distance_covered += split_km
      distance_covered = total_distance if distance_covered > total_distance

      if distance_covered <= half_distance
        # First half
        cumulative_time = distance_covered * first_half_pace
      else
        # Second half
        time_at_halfway = half_distance * first_half_pace
        distance_in_second_half = distance_covered - half_distance
        cumulative_time = time_at_halfway + (distance_in_second_half * second_half_pace)
      end

      splits << convert_to_clocktime(cumulative_time.round)
    end

    splits
  end
end
