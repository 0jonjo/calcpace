# frozen_string_literal: true

# Module for calculating race times and paces for standard distances
#
# This module provides convenience methods for calculating finish times
# and paces for common race distances like 5K, 10K, half-marathon, and marathon.
module PaceCalculator
  # Standard race distances in kilometers
  RACE_DISTANCES = {
    '5k' => 5.0,
    '10k' => 10.0,
    'half_marathon' => 21.0975,
    'marathon' => 42.195
  }.freeze

  # Calculates the finish time for a race given a pace per kilometer
  #
  # @param pace_per_km [Numeric, String] pace in seconds per km or time string (MM:SS)
  # @param race [String, Symbol] race distance ('5k', '10k', 'half_marathon', 'marathon')
  # @return [Float] total time in seconds
  # @raise [ArgumentError] if race distance is not recognized
  #
  # @example
  #   race_time(300, :5k)           #=> 1500.0 (5:00/km pace for 5K = 25:00)
  #   race_time('05:00', :marathon) #=> 12658.5 (5:00/km pace for marathon = 3:30:58)
  def race_time(pace_per_km, race)
    distance = race_distance(race)
    pace_seconds = pace_per_km.is_a?(String) ? convert_to_seconds(pace_per_km) : pace_per_km
    check_positive(pace_seconds, 'Pace')
    distance * pace_seconds
  end

  # Calculates the finish time for a race and returns it as a clock time string
  #
  # @param pace_per_km [Numeric, String] pace in seconds per km or time string (MM:SS)
  # @param race [String, Symbol] race distance ('5k', '10k', 'half_marathon', 'marathon')
  # @return [String] finish time in HH:MM:SS format
  #
  # @example
  #   race_time_clock('05:00', :marathon) #=> '03:30:58'
  #   race_time_clock(300, :half_marathon) #=> '01:45:17'
  def race_time_clock(pace_per_km, race)
    convert_to_clocktime(race_time(pace_per_km, race))
  end

  # Calculates the required pace per kilometer to finish a race in a target time
  #
  # @param target_time [Numeric, String] target finish time in seconds or time string (HH:MM:SS)
  # @param race [String, Symbol] race distance ('5k', '10k', 'half_marathon', 'marathon')
  # @return [Float] required pace in seconds per kilometer
  #
  # @example
  #   race_pace('03:30:00', :marathon)    #=> 297.48... (4:57/km to finish in 3:30)
  #   race_pace(1800, :5k)                #=> 360.0 (6:00/km to finish in 30:00)
  def race_pace(target_time, race)
    distance = race_distance(race)
    time_seconds = target_time.is_a?(String) ? convert_to_seconds(target_time) : target_time
    check_positive(time_seconds, 'Time')
    time_seconds / distance
  end

  # Calculates the required pace and returns it as a clock time string
  #
  # @param target_time [Numeric, String] target finish time in seconds or time string (HH:MM:SS)
  # @param race [String, Symbol] race distance ('5k', '10k', 'half_marathon', 'marathon')
  # @return [String] required pace in MM:SS format
  #
  # @example
  #   race_pace_clock('03:30:00', :marathon) #=> '00:04:57'
  def race_pace_clock(target_time, race)
    convert_to_clocktime(race_pace(target_time, race))
  end

  # Lists all available standard race distances
  #
  # @return [Hash] hash of race names and distances in kilometers
  #
  # @example
  #   list_races #=> { '5k' => 5.0, '10k' => 10.0, ... }
  def list_races
    RACE_DISTANCES.dup
  end

  private

  # Gets the distance for a standard race
  #
  # @param race [String, Symbol] race name
  # @return [Float] distance in kilometers
  # @raise [ArgumentError] if race is not recognized
  def race_distance(race)
    key = race.to_s.downcase
    RACE_DISTANCES.fetch(key) do
      raise ArgumentError,
            "Unknown race: #{race}. Available races: #{RACE_DISTANCES.keys.join(', ')}"
    end
  end
end
