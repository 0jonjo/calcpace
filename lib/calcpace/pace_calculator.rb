# frozen_string_literal: true

# Module for calculating race times and paces for standard distances
#
# This module provides convenience methods for calculating finish times
# and paces for common race distances like 5K, 10K, half-marathon, marathon, and 100K.
module PaceCalculator
  # Standard race distances in kilometers
  RACE_DISTANCES = {
    '5k' => 5.0,
    '10k' => 10.0,
    'half_marathon' => 21.0975,
    'marathon' => 42.195,
    '100k' => 100.0,
    '1mile' => Converter::Distance::MI_TO_KM,
    '5mile' => 5 * Converter::Distance::MI_TO_KM,
    '10mile' => 10 * Converter::Distance::MI_TO_KM
  }.freeze

  # Relative window under which two distances count as the same race. It exists
  # only to absorb floating-point noise, never to call two different distances
  # equal — 10.0 km and 10.2 km are a legitimate prediction, not a mistake
  SAME_DISTANCE_TOLERANCE_RATIO = 1e-9

  # Calculates the finish time for a race given a pace per kilometer
  #
  # @param pace_per_km [Numeric, String] pace in seconds per km or time string (MM:SS)
  # @param race [Numeric, String, Symbol] distance in kilometers (7.79, '7.79') or a
  #   standard race name ('5k', '10k', 'half_marathon', 'marathon', '100k', ...)
  # @return [Float] total time in seconds
  # @raise [ArgumentError] if a race name is not recognized
  # @raise [Calcpace::NonPositiveInputError] if a numeric distance is not positive
  #
  # @example
  #   race_time(300, '5k')          #=> 1500.0 (5:00/km pace for 5K = 25:00)
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
  # @param race [Numeric, String, Symbol] distance in kilometers (7.79, '7.79') or a
  #   standard race name ('5k', '10k', 'half_marathon', 'marathon', '100k', ...)
  # @return [String] finish time in HH:MM:SS format
  #
  # @example
  #   race_time_clock('05:00', :marathon) #=> '03:30:58'
  #   race_time_clock(300, :half_marathon) #=> '01:45:29'
  def race_time_clock(pace_per_km, race)
    convert_to_clocktime(race_time(pace_per_km, race))
  end

  # Calculates the required pace per kilometer to finish a race in a target time
  #
  # @param target_time [Numeric, String] target finish time in seconds or time string (HH:MM:SS)
  # @param race [Numeric, String, Symbol] distance in kilometers (7.79, '7.79') or a
  #   standard race name ('5k', '10k', 'half_marathon', 'marathon', '100k', ...)
  # @return [Float] required pace in seconds per kilometer
  #
  # @example
  #   race_pace('03:30:00', :marathon)    #=> 298.61... (4:58/km to finish in 3:30)
  #   race_pace(1800, '5k')               #=> 360.0 (6:00/km to finish in 30:00)
  def race_pace(target_time, race)
    distance = race_distance(race)
    time_seconds = target_time.is_a?(String) ? convert_to_seconds(target_time) : target_time
    check_positive(time_seconds, 'Time')
    time_seconds / distance
  end

  # Calculates the required pace and returns it as a clock time string
  #
  # @param target_time [Numeric, String] target finish time in seconds or time string (HH:MM:SS)
  # @param race [Numeric, String, Symbol] distance in kilometers (7.79, '7.79') or a
  #   standard race name ('5k', '10k', 'half_marathon', 'marathon', '100k', ...)
  # @return [String] required pace in MM:SS format
  #
  # @example
  #   race_pace_clock('03:30:00', :marathon) #=> '00:04:58'
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

  # Resolves a race argument to a distance in kilometers
  #
  # A standard race name resolves through RACE_DISTANCES; a distance resolves
  # to itself. Numeric strings ('7.79') count as distances — the convention
  # TrainingZones#training_paces_from_race and FitnessPredictor already follow,
  # so 7.79 and '7.79' can never mean two different things.
  #
  # @param race [Numeric, String, Symbol] race name or distance in kilometers
  # @return [Float] distance in kilometers
  # @raise [ArgumentError] if a race name is not recognized
  # @raise [Calcpace::NonPositiveInputError] if a numeric distance is not positive
  def race_distance(race)
    numeric = numeric_distance(race)
    return numeric if numeric

    RACE_DISTANCES.fetch(normalize_race_key(race)) do
      raise ArgumentError,
            "Unknown race: #{race}. Available races: #{RACE_DISTANCES.keys.join(', ')}"
    end
  end

  # Reads a race argument as a plain distance, or nil when it is a race name
  #
  # @param race [Numeric, String, Symbol] race name or distance in kilometers
  # @return [Float, nil] the distance in kilometers, nil for a non-numeric input
  # @raise [Calcpace::NonPositiveInputError] if the distance is not positive
  def numeric_distance(race)
    value = race.is_a?(Numeric) ? race.to_f : Float(race, exception: false)
    return nil unless value

    check_positive(value, 'Distance')
    value
  end

  # Guards the "predict a distance from itself" call, which has no answer to give
  #
  # @param from_distance [Float] known distance in kilometers
  # @param to_distance [Float] target distance in kilometers
  # @raise [ArgumentError] if both distances are the same race
  def ensure_different_distances!(from_distance, to_distance)
    return unless same_distance?(from_distance, to_distance)

    raise ArgumentError,
          "From and to races must be different distances (both are #{from_distance}km)"
  end

  # Two distances are the same race only when they differ by representation
  # noise — a window narrow enough that any distance a runner actually types is
  # outside it. Deciding when two genuinely different distances are close
  # enough to count as the same race is age grading's business, and it has its
  # own, much wider, explicit tolerance
  def same_distance?(one, other)
    (one - other).abs <= [one.abs, other.abs].max * SAME_DISTANCE_TOLERANCE_RATIO
  end

  # Single normalization for every race-name lookup in the gem (here and in
  # AgeGrading), so ' 10K ' and :marathon always resolve like '10k' and 'marathon'
  #
  # @param race [String, Symbol] race name in any case, with or without padding
  # @return [String] normalized lookup key
  def normalize_race_key(race)
    race.to_s.strip.downcase
  end
end
