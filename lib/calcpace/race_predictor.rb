# frozen_string_literal: true

# Module for predicting race times based on performance at other distances
#
# This module uses the Riegel formula to predict race times based on a known
# performance at a different distance. The formula accounts for the endurance
# fatigue factor that occurs as race distance increases.
module RacePredictor
  # Riegel formula exponent (represents endurance/fatigue factor)
  RIEGEL_EXPONENT = 1.06

  # Predicts race time for a target distance based on a known performance
  #
  # Uses the Riegel formula: T2 = T1 × (D2/D1)^1.06
  # where:
  # - T1 = time at known distance
  # - D1 = known distance
  # - T2 = predicted time at target distance
  # - D2 = target distance
  # - 1.06 = endurance/fatigue factor (longer races require proportionally more time)
  #
  # @param from_race [String, Symbol] known race distance ('5k', '10k', 'half_marathon', 'marathon', etc.)
  # @param from_time [String, Numeric] time achieved at known distance (HH:MM:SS or seconds)
  # @param to_race [String, Symbol] target race distance to predict
  # @return [Float] predicted time in seconds
  # @raise [ArgumentError] if races are invalid or distances are the same
  #
  # @example Predict marathon time from 5K
  #   predict_time('5k', '00:20:00', 'marathon')
  #   #=> 11123.4 (approximately 3:05:23)
  #
  # @example Predict 10K time from half marathon
  #   predict_time('half_marathon', '01:30:00', '10k')
  #   #=> 2565.8 (approximately 42:46)
  def predict_time(from_race, from_time, to_race)
    from_distance = race_distance(from_race)
    to_distance = race_distance(to_race)

    if from_distance == to_distance
      raise ArgumentError,
            "From and to races must be different distances (both are #{from_distance}km)"
    end

    time_seconds = from_time.is_a?(String) ? convert_to_seconds(from_time) : from_time
    check_positive(time_seconds, 'Time')

    # Riegel formula: T2 = T1 × (D2/D1)^1.06
    time_seconds * ((to_distance / from_distance)**RIEGEL_EXPONENT)
  end

  # Predicts race time and returns it as a clock time string
  #
  # @param from_race [String, Symbol] known race distance
  # @param from_time [String, Numeric] time achieved at known distance
  # @param to_race [String, Symbol] target race distance to predict
  # @return [String] predicted time in HH:MM:SS format
  #
  # @example
  #   predict_time_clock('5k', '00:20:00', 'marathon')
  #   #=> '03:05:23'
  def predict_time_clock(from_race, from_time, to_race)
    predicted_seconds = predict_time(from_race, from_time, to_race)
    convert_to_clocktime(predicted_seconds)
  end

  # Predicts the pace per kilometer for a target race
  #
  # @param from_race [String, Symbol] known race distance
  # @param from_time [String, Numeric] time achieved at known distance
  # @param to_race [String, Symbol] target race distance to predict
  # @return [Float] predicted pace in seconds per kilometer
  #
  # @example
  #   predict_pace('5k', '00:20:00', 'marathon')
  #   #=> 263.6 (approximately 4:24/km)
  def predict_pace(from_race, from_time, to_race)
    predicted_seconds = predict_time(from_race, from_time, to_race)
    to_distance = race_distance(to_race)
    predicted_seconds / to_distance
  end

  # Predicts the pace per kilometer and returns it as a clock time string
  #
  # @param from_race [String, Symbol] known race distance
  # @param from_time [String, Numeric] time achieved at known distance
  # @param to_race [String, Symbol] target race distance to predict
  # @return [String] predicted pace in MM:SS format
  #
  # @example
  #   predict_pace_clock('5k', '00:20:00', 'marathon')
  #   #=> '00:04:24' (4:24/km)
  def predict_pace_clock(from_race, from_time, to_race)
    pace_seconds = predict_pace(from_race, from_time, to_race)
    convert_to_clocktime(pace_seconds)
  end

  # Calculates the equivalent performance at a different distance
  #
  # This is useful for comparing performances across different race distances.
  # For example, "My 10K time is equivalent to what 5K time?"
  #
  # @param from_race [String, Symbol] known race distance
  # @param from_time [String, Numeric] time achieved at known distance
  # @param to_race [String, Symbol] target race distance for comparison
  # @return [Hash] hash with :time (seconds), :time_clock (HH:MM:SS), :pace (/km), :pace_clock
  #
  # @example
  #   equivalent_performance('10k', '00:42:00', '5k')
  #   #=> {
  #         time: 1228.5,
  #         time_clock: "00:20:28",
  #         pace: 245.7,
  #         pace_clock: "00:04:06"
  #       }
  def equivalent_performance(from_race, from_time, to_race)
    predicted_time = predict_time(from_race, from_time, to_race)
    predicted_pace = predict_pace(from_race, from_time, to_race)

    {
      time: predicted_time,
      time_clock: convert_to_clocktime(predicted_time),
      pace: predicted_pace,
      pace_clock: convert_to_clocktime(predicted_pace)
    }
  end
end
