# frozen_string_literal: true

# Module for predicting race times using the Cameron formula
#
# An alternative to the Riegel formula (RacePredictor module) that uses an
# exponential correction to better account for physiological differences across
# distances. The correction is larger when predicting from shorter races, where
# anaerobic contribution is greater, and diminishes as the known distance approaches
# the target distance.
#
# Formula: T2 = T1 × (D2/D1) × [(a + b × e^(-D1/c)) / (a + b × e^(-D2/c))]
#
# Constants (calibrated for distances in km):
#   a = 0.000495
#   b = 0.000985
#   c = 1.4485
#
# Reference: Dave Cameron, "A Critical Examination of Racing Predictions" (1997)
module CameronPredictor
  # Cameron formula constants (calibrated for distances in km)
  CAMERON_A = 0.000495
  CAMERON_B = 0.000985
  CAMERON_C = 1.4485

  # Predicts race time using the Cameron formula
  #
  # @param from_race [Numeric, String, Symbol] known distance in kilometers (7.79,
  #   '7.79') or a standard race name ('5k', '10k', 'half_marathon', 'marathon', '100k', etc.)
  # @param from_time [String, Numeric] time achieved at known distance (HH:MM:SS or seconds)
  # @param to_race [Numeric, String, Symbol] target distance in kilometers or race name
  # @return [Float] predicted time in seconds
  # @raise [ArgumentError] if races are invalid or distances are the same
  #
  # @example Predict marathon time from 10K
  #   predict_time_cameron('10k', '00:42:00', 'marathon')
  #   #=> ~10,654 seconds (approximately 2:57:34)
  #
  # @example Predict 10K time from 5K
  #   predict_time_cameron('5k', '00:20:00', '10k')
  #   #=> ~2,546 seconds (approximately 42:26)
  def predict_time_cameron(from_race, from_time, to_race)
    from_distance = race_distance(from_race)
    to_distance   = race_distance(to_race)

    ensure_different_distances!(from_distance, to_distance)

    time_seconds = from_time.is_a?(String) ? convert_to_seconds(from_time) : from_time
    check_positive(time_seconds, 'Time')

    # Cameron formula: T2 = T1 × (D2/D1) × [cameron_factor(D1) / cameron_factor(D2)]
    time_seconds * (to_distance / from_distance) *
      (cameron_factor(from_distance) / cameron_factor(to_distance))
  end

  # Predicts race time using the Cameron formula, returned as a clock time string
  #
  # @param from_race [Numeric, String, Symbol] known distance in kilometers or race name
  # @param from_time [String, Numeric] time achieved at known distance
  # @param to_race [Numeric, String, Symbol] target distance in kilometers or race name
  # @return [String] predicted time in HH:MM:SS format
  #
  # @example
  #   predict_time_cameron_clock('10k', '00:42:00', 'marathon')
  #   #=> '02:57:34'
  def predict_time_cameron_clock(from_race, from_time, to_race)
    convert_to_clocktime(predict_time_cameron(from_race, from_time, to_race))
  end

  # Predicts pace per kilometer using the Cameron formula
  #
  # @param from_race [Numeric, String, Symbol] known distance in kilometers or race name
  # @param from_time [String, Numeric] time achieved at known distance
  # @param to_race [Numeric, String, Symbol] target distance in kilometers or race name
  # @return [Float] predicted pace in seconds per kilometer
  #
  # @example
  #   predict_pace_cameron('5k', '00:20:00', 'marathon')
  #   #=> ~255.1 (approximately 4:15/km)
  def predict_pace_cameron(from_race, from_time, to_race)
    predict_time_cameron(from_race, from_time, to_race) / race_distance(to_race)
  end

  # Predicts pace per kilometer using the Cameron formula, returned as a clock time string
  #
  # @param from_race [Numeric, String, Symbol] known distance in kilometers or race name
  # @param from_time [String, Numeric] time achieved at known distance
  # @param to_race [Numeric, String, Symbol] target distance in kilometers or race name
  # @return [String] predicted pace in HH:MM:SS format
  #
  # @example
  #   predict_pace_cameron_clock('5k', '00:20:00', 'marathon')
  #   #=> '00:04:15'
  def predict_pace_cameron_clock(from_race, from_time, to_race)
    convert_to_clocktime(predict_pace_cameron(from_race, from_time, to_race))
  end

  # Predicts race time adjusted for environmental conditions using Cameron formula
  #
  # @param from_race [Numeric, String, Symbol] known distance in kilometers or race name
  # @param from_time [String, Numeric] time achieved at known distance
  # @param to_race [Numeric, String, Symbol] target distance in kilometers or race name
  # @param options [Hash] environmental options (temperature, altitude, etc.)
  # @return [Hash] hash with adjusted prediction and penalty details
  def predict_time_cameron_adjusted(from_race, from_time, to_race, **)
    predicted_seconds = predict_time_cameron(from_race, from_time, to_race)
    adjust_time(predicted_seconds, **)
  end

  private

  # Computes the Cameron exponential correction factor for a given distance
  #
  # @param distance_km [Float] distance in kilometers
  # @return [Float] correction factor value
  def cameron_factor(distance_km)
    CAMERON_A + (CAMERON_B * Math.exp(-distance_km / CAMERON_C))
  end
end
