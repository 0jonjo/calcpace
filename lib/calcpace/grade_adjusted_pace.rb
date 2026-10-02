# frozen_string_literal: true

# Module for grade-adjusted pace (GAP): the flat-ground pace that costs the
# same energy as a pace run on a slope
#
# Uses the energy cost of running on gradients measured by Minetti et al.
# (2002) on ten runners on a treadmill inclined from −45% to +45%:
#
#   Cr(i) = 155.4·i⁵ − 30.4·i⁴ − 43.3·i³ + 46.3·i² + 19.5·i + 3.6   (R² = 0.999)
#
# where Cr is the metabolic cost in J·kg⁻¹·m⁻¹ and i the gradient as a
# fraction (rise over horizontal run, 0.05 = 5%). The adjustment factor is
# Cr(i) / Cr(0): running a metre of 10% climb costs about 1.66 flat metres,
# a metre of 10% descent about 0.60. Cost is cheapest near −20% and rises
# again on steeper descents, where braking takes over.
#
# The flat-equivalent pace is pace / factor: the speed that, on level ground,
# spends energy at the same rate. Minetti found the cost per metre independent
# of speed, so the factor does not depend on how fast the runner is going.
#
# Limits worth knowing:
# - The polynomial is a fit to treadmill measurements between −0.45 and +0.45;
#   grades outside that range are clamped to it rather than extrapolated.
# - It is a metabolic model. It does not account for the muscular cost of long
#   descents, technical terrain or the fact that a runner rarely holds the
#   metabolic equivalent on a steep climb — field GAP models fitted to heart
#   rate (Strava's, for instance) are gentler on climbs.
# - Its constant term (3.6) is the fit's value on the flat; Minetti measured
#   3.40 ± 0.24 J·kg⁻¹·m⁻¹ there. The factor divides by Cr(0) so it is exactly
#   1.0 on the flat.
#
# Reference: Minetti, A. E., Moia, C., Roi, G. S., Susta, D., & Ferretti, G.
# (2002). Energy cost of walking and running at extreme uphill and downhill
# slopes. Journal of Applied Physiology, 93(3), 1039–1046.
# https://doi.org/10.1152/japplphysiol.01177.2001
module GradeAdjustedPace
  # Gradient range of Minetti et al.'s measurements, as fractions
  MINETTI_GRADE_RANGE = (-0.45..0.45)

  # Polynomial coefficients for Cr(i), highest power first (J·kg⁻¹·m⁻¹)
  MINETTI_RUNNING_COEFFICIENTS = [155.4, -30.4, -43.3, 46.3, 19.5, 3.6].freeze

  # Returns how many flat metres one metre at a given gradient is worth
  #
  # @param grade [Numeric] gradient as a fraction (0.05 = 5% uphill, −0.05 = 5%
  #   downhill); clamped to −0.45..0.45, the range Minetti et al. measured
  # @return [Float] Cr(grade) / Cr(0) — 1.0 on the flat, above 1 uphill,
  #   below 1 on moderate descents
  # @raise [ArgumentError] if grade is not a finite number
  #
  # @example
  #   calc.grade_adjustment_factor(0)     #=> 1.0
  #   calc.grade_adjustment_factor(0.1)   #=> 1.6578372222222222
  #   calc.grade_adjustment_factor(-0.1)  #=> 0.5976961111111111
  def grade_adjustment_factor(grade)
    check_grade(grade)

    minetti_running_cost(grade.to_f.clamp(MINETTI_GRADE_RANGE)) / minetti_running_cost(0.0)
  end

  # Converts a pace run on a slope into the flat pace of equal effort
  #
  # @param pace [Numeric, String] pace in seconds per unit or time string (MM:SS or HH:MM:SS)
  # @param grade [Numeric] gradient as a fraction (see #grade_adjustment_factor)
  # @param unit [Symbol, String] unit the pace is expressed in — :km (default) or
  #   :mi. The factor is per distance, so the result comes back in the same unit
  #   and the unit only has to be a supported one
  # @return [Float] flat-equivalent pace in seconds per unit
  # @raise [ArgumentError] if grade is not a finite number
  # @raise [Calcpace::NonPositiveInputError] if pace is not positive
  # @raise [Calcpace::InvalidTimeFormatError] if a string pace is not a valid clock
  # @raise [Calcpace::UnsupportedUnitError] if unit is not :km or :mi
  #
  # @example
  #   calc.grade_adjusted_pace(360, 0.1)              #=> 217.1503903847952
  #   calc.grade_adjusted_pace('05:00', -0.05)        #=> 393.31023895122013
  #   calc.grade_adjusted_pace(480, 0.05, unit: :mi)  #=> 368.82127811700303
  def grade_adjusted_pace(pace, grade, unit: :km)
    pace_unit_meters(unit)
    factor = grade_adjustment_factor(grade)
    pace_seconds = pace_seconds_from(pace)
    check_positive(pace_seconds, 'Pace')

    pace_seconds.to_f / factor
  end

  # Grade-adjusted pace as a clock string
  #
  # @param pace [Numeric, String] pace in seconds per unit or time string
  # @param grade [Numeric] gradient as a fraction
  # @param unit [Symbol, String] unit the pace is expressed in — :km (default) or :mi
  # @param compact [Boolean] when true, return the compact display format
  # @return [String] flat-equivalent pace in HH:MM:SS format, or 'M:SS' / 'H:MM:SS'
  #   with compact: true
  #
  # @example
  #   calc.grade_adjusted_pace_clock('06:00', 0.1)                 #=> '00:03:37'
  #   calc.grade_adjusted_pace_clock('06:00', 0.1, compact: true)  #=> '3:37'
  def grade_adjusted_pace_clock(pace, grade, unit: :km, compact: false)
    convert_to_clocktime(grade_adjusted_pace(pace, grade, unit: unit), compact: compact)
  end

  private

  def check_grade(grade)
    return if grade.is_a?(Numeric) && grade.to_f.finite?

    raise ArgumentError, "Grade must be a finite number (a fraction: 0.05 = 5%), got #{grade.inspect}"
  end

  def minetti_running_cost(grade)
    MINETTI_RUNNING_COEFFICIENTS.reduce(0.0) { |sum, coefficient| (sum * grade) + coefficient }
  end
end
