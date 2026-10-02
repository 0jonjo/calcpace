# frozen_string_literal: true

# Module for predicting race times using the Cameron formula
#
# An alternative to the Riegel formula (RacePredictor module). Dave Cameron fitted
# a velocity-ratio function to world-best times from 800 m to the marathon; unlike
# Riegel's single power law, the drop-off it predicts grows with distance, so it is
# more conservative than Riegel when predicting the marathon from shorter races.
#
# Formula (distances in metres, times in seconds):
#   f(d) = 13.49681 − 0.000030363 × d + 835.7114 / d^0.7905
#   T2   = T1 × (D2/D1) × f(D1) / f(D2)
#
# Distances are accepted in kilometres (or as race names) like every other method
# in this gem, and converted to metres before f(d) is evaluated.
#
# References:
# - Dave Cameron, metric version of his model posted to the t-and-f mailing list,
#   20 Jun 2001: https://www.mail-archive.com/t-and-f@lists.uoregon.edu/msg11312.html
# - had2know.org Cameron calculator (same constants, distances in metres; worked
#   example 3.5 mi in 51:30 → 5 mi in ~75:08):
#   https://www.had2know.org/sports/race-performance-prediction-calculator-cameron.html
module CameronPredictor
  # Constant term of Cameron's velocity-ratio function f(d)
  CAMERON_CONSTANT = 13.49681
  # Linear coefficient of f(d), per metre
  CAMERON_LINEAR_COEFFICIENT = 0.000030363
  # Numerator of the power term of f(d)
  CAMERON_POWER_COEFFICIENT = 835.7114
  # Exponent of the power term of f(d)
  CAMERON_POWER_EXPONENT = 0.7905

  # Predicts race time using the Cameron formula
  #
  # @param from_race [Numeric, String, Symbol] known distance in kilometers (7.79,
  #   '7.79') or a standard race name ('5k', '10k', 'half_marathon', 'marathon', '100k', etc.)
  # @param from_time [String, Numeric] time achieved at known distance (HH:MM:SS or seconds)
  # @param to_race [Numeric, String, Symbol] target distance in kilometers or race name
  # @return [Float] predicted time in seconds
  # @raise [ArgumentError] if a race name is invalid or the distances are the same
  # @raise [Calcpace::NonPositiveInputError] if a numeric distance is not positive
  #
  # @example Predict marathon time from 10K
  #   predict_time_cameron('10k', '00:42:00', 'marathon')
  #   #=> ~11,807 seconds (approximately 3:16:46)
  #
  # @example Predict 10K time from 5K
  #   predict_time_cameron('5k', '00:20:00', '10k')
  #   #=> ~2,500 seconds (approximately 41:39)
  def predict_time_cameron(from_race, from_time, to_race)
    from_distance = race_distance(from_race)
    to_distance   = race_distance(to_race)

    ensure_different_distances!(from_distance, to_distance)

    time_seconds = from_time.is_a?(String) ? convert_to_seconds(from_time) : from_time
    check_positive(time_seconds, 'Time')

    # Cameron formula: T2 = T1 × (D2/D1) × [f(D1) / f(D2)]
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
  #   #=> '03:16:46'
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
  #   #=> ~277.6 (approximately 4:37/km)
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
  #   #=> '00:04:37'
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

  # Evaluates Cameron's velocity-ratio function f(d) for a given distance
  #
  # @param distance_km [Float] distance in kilometers (converted to metres, the
  #   unit Cameron's constants are calibrated for)
  # @return [Float] value of f(d)
  def cameron_factor(distance_km)
    meters = distance_km * 1000.0
    CAMERON_CONSTANT - (CAMERON_LINEAR_COEFFICIENT * meters) +
      (CAMERON_POWER_COEFFICIENT / (meters**CAMERON_POWER_EXPONENT))
  end
end
