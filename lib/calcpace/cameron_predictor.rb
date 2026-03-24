# frozen_string_literal: true

# Module for predicting race times using the Cameron formula
#
# An alternative to the Riegel formula (RacePredictor module) that uses an
# exponential correction to better account for physiological differences across
# distances. The correction is larger when predicting from shorter races, where
# aerobic capacity is more dominant, and diminishes as the known distance approaches
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
  # @param from_race [String, Symbol] known race distance ('5k', '10k', 'half_marathon', 'marathon', etc.)
  # @param from_time [String, Numeric] time achieved at known distance (HH:MM:SS or seconds)
  # @param to_race [String, Symbol] target race distance to predict
  # @return [Float] predicted time in seconds
  # @raise [ArgumentError] if races are invalid or distances are the same
  #
  # @example Predict marathon time from 10K
  #   predict_time_cameron('10k', '00:42:00', 'marathon')
  #   #=> ~10,666 seconds (approximately 2:57:46)
  #
  # @example Predict 10K time from 5K
  #   predict_time_cameron('5k', '00:20:00', '10k')
  #   #=> ~2,544 seconds (approximately 42:24)
  def predict_time_cameron(from_race, from_time, to_race)
    from_distance = race_distance(from_race)
    to_distance   = race_distance(to_race)

    if from_distance == to_distance
      raise ArgumentError,
            "From and to races must be different distances (both are #{from_distance}km)"
    end

    time_seconds = from_time.is_a?(String) ? convert_to_seconds(from_time) : from_time
    check_positive(time_seconds, 'Time')

    # Cameron formula: T2 = T1 × (D2/D1) × [cameron_factor(D1) / cameron_factor(D2)]
    time_seconds * (to_distance / from_distance) *
      (cameron_factor(from_distance) / cameron_factor(to_distance))
  end

  # Predicts race time using the Cameron formula, returned as a clock time string
  #
  # @param from_race [String, Symbol] known race distance
  # @param from_time [String, Numeric] time achieved at known distance
  # @param to_race [String, Symbol] target race distance to predict
  # @return [String] predicted time in HH:MM:SS format
  #
  # @example
  #   predict_time_cameron_clock('10k', '00:42:00', 'marathon')
  #   #=> '02:57:46'
  def predict_time_cameron_clock(from_race, from_time, to_race)
    convert_to_clocktime(predict_time_cameron(from_race, from_time, to_race))
  end

  # Predicts pace per kilometer using the Cameron formula
  #
  # @param from_race [String, Symbol] known race distance
  # @param from_time [String, Numeric] time achieved at known distance
  # @param to_race [String, Symbol] target race distance to predict
  # @return [Float] predicted pace in seconds per kilometer
  #
  # @example
  #   predict_pace_cameron('5k', '00:20:00', 'marathon')
  #   #=> ~152.5 (approximately 2:32/km)
  def predict_pace_cameron(from_race, from_time, to_race)
    predict_time_cameron(from_race, from_time, to_race) / race_distance(to_race)
  end

  # Predicts pace per kilometer using the Cameron formula, returned as a clock time string
  #
  # @param from_race [String, Symbol] known race distance
  # @param from_time [String, Numeric] time achieved at known distance
  # @param to_race [String, Symbol] target race distance to predict
  # @return [String] predicted pace in HH:MM:SS format
  #
  # @example
  #   predict_pace_cameron_clock('5k', '00:20:00', 'marathon')
  #   #=> '00:02:32'
  def predict_pace_cameron_clock(from_race, from_time, to_race)
    convert_to_clocktime(predict_pace_cameron(from_race, from_time, to_race))
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
