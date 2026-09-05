# frozen_string_literal: true

# Module relating pace, cadence and stride length
#
# The three quantities are one identity, not three measurements:
#   speed (m/min) = unit_metres / pace_seconds * 60
#   stride (m)    = speed / cadence
# so any two of them give the third. Cadence here is steps per minute counting
# BOTH feet (spm) — the number a watch shows during a run. Strava's API reports
# cadence as one-leg RPM, so a caller reading it from there must double it
# before passing it in.
module StrideCalculator
  # Calculates stride length from pace and cadence
  #
  # @param pace [Numeric, String] pace in seconds per unit or time string (MM:SS or HH:MM:SS)
  # @param cadence [Numeric] cadence in steps per minute, both feet (must be > 0)
  # @param unit [Symbol, String] unit the pace is expressed in — :km (default) or :mi
  # @return [Float] stride length in metres per step, rounded to 2 decimals
  # @raise [Calcpace::InvalidTimeFormatError] if pace is a string that is not a valid clock
  # @raise [Calcpace::NonPositiveInputError] if pace or cadence is not positive
  # @raise [Calcpace::UnsupportedUnitError] if unit is not :km or :mi
  #
  # @example
  #   # 300 s/km → 200 m/min; 200/170
  #   calc.stride_length('05:00', 170)             #=> 1.18
  #   # numeric seconds per km
  #   calc.stride_length(300, 170)                 #=> 1.18
  #   # 8:02/mi is 5:00/km rounded down to the second
  #   calc.stride_length('08:02', 170, unit: :mi)  #=> 1.18
  def stride_length(pace, cadence, unit: :km)
    speed = speed_meters_per_minute(pace, unit)
    check_positive(cadence, 'Cadence')

    (speed / cadence).round(2)
  end

  # Calculates the cadence a given stride length implies at a given pace
  #
  # The inverse of #stride_length: it answers what turnover a runner needs to
  # hold a pace with the stride they actually have.
  #
  # @param pace [Numeric, String] pace in seconds per unit or time string (MM:SS or HH:MM:SS)
  # @param stride [Numeric] stride length in metres per step (must be > 0)
  # @param unit [Symbol, String] unit the pace is expressed in — :km (default) or :mi
  # @return [Float] cadence in steps per minute, both feet, rounded to 1 decimal
  # @raise [Calcpace::InvalidTimeFormatError] if pace is a string that is not a valid clock
  # @raise [Calcpace::NonPositiveInputError] if pace or stride is not positive
  # @raise [Calcpace::UnsupportedUnitError] if unit is not :km or :mi
  #
  # @example
  #   # 200 m/min / 1.18 m
  #   calc.cadence_for_stride('05:00', 1.18)  #=> 169.5
  #   calc.cadence_for_stride('05:30', 1.15)  #=> 158.1
  def cadence_for_stride(pace, stride, unit: :km)
    speed = speed_meters_per_minute(pace, unit)
    check_positive(stride, 'Stride')

    (speed / stride).round(1)
  end

  private

  # Turns a pace (clock string or seconds per unit) into a running speed
  #
  # A String pace is checked as a clock before it is parsed, the way
  # Calculator#validate_time, Vo2maxEstimator and AgeGrading check theirs — so
  # '05:xx' is a format error, not a silently truncated pace. The unit is
  # resolved first, so a bad unit wins over a bad pace, as it does in
  # FitnessPredictor#race_times_from_vo2max.
  #
  # @param pace [Numeric, String] pace in seconds per unit or time string
  # @param unit [Symbol, String] :km or :mi
  # @return [Float] speed in metres per minute
  def speed_meters_per_minute(pace, unit)
    meters = pace_unit_meters(unit)
    pace_seconds = pace_seconds_from(pace)
    check_positive(pace_seconds, 'Pace')

    meters / pace_seconds * 60.0
  end

  # @param pace [Numeric, String] pace in seconds per unit or time string
  # @return [Numeric] the pace in seconds
  # @raise [Calcpace::InvalidTimeFormatError] if a string pace is not a valid clock
  def pace_seconds_from(pace)
    return pace unless pace.is_a?(String)

    check_time(pace)
    convert_to_seconds(pace)
  end
end
