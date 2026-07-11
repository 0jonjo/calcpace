# frozen_string_literal: true

# Module for deriving personalized training zones from VO2max
#
# Training paces invert the Daniels & Gilbert (1979) velocity equation:
#   VO2 = -4.60 + 0.182258 * v + 0.000104 * v²   (v in m/min)
# Solving the quadratic for v at a target %VO2max gives the running
# velocity for each training intensity (Daniels' Running Formula).
#
# Heart rate zones use the Karvonen method (Heart Rate Reserve):
#   target = hr_rest + pct * (hr_max - hr_rest)
module TrainingZones
  # Training intensities as fraction of VO2max (Daniels' Running Formula)
  TRAINING_INTENSITIES = {
    easy: { low: 0.59, high: 0.74 },
    marathon: { low: 0.75, high: 0.84 },
    threshold: { low: 0.83, high: 0.88 },
    interval: { low: 0.95, high: 1.00 },
    repetition: { low: 1.05, high: 1.10 }
  }.freeze

  # A pace band for one training zone (paces per kilometre).
  # slow = lower-intensity end of the band, fast = higher-intensity end.
  PaceBand = Struct.new(:slow_seconds, :fast_seconds, :slow_clock, :fast_clock)

  # Derives training pace bands from a VO2max value
  #
  # @param vo2max [Numeric] VO2max in ml/kg/min (must be > 0)
  # @return [Hash{Symbol => PaceBand}] keys: :easy, :marathon, :threshold,
  #   :interval, :repetition — paces per km
  # @raise [Calcpace::NonPositiveInputError] if vo2max is not positive
  #
  # @example
  #   calc.training_paces(50.0)[:threshold].fast_clock #=> "00:04:15"
  def training_paces(vo2max)
    check_positive(vo2max.to_f, 'VO2max')

    TRAINING_INTENSITIES.transform_values do |band|
      slow = pace_seconds_at_pct(vo2max.to_f, band[:low])
      fast = pace_seconds_at_pct(vo2max.to_f, band[:high])

      PaceBand.new(
        slow_seconds: slow,
        fast_seconds: fast,
        slow_clock: convert_to_clocktime(slow),
        fast_clock: convert_to_clocktime(fast)
      )
    end
  end

  private

  # Inverts Daniels & Gilbert: velocity (m/min) that demands a given VO2
  def velocity_at_vo2(vo2)
    a = 0.000104
    b = 0.182258
    c = -(4.60 + vo2)

    (-b + Math.sqrt((b**2) - (4 * a * c))) / (2 * a)
  end

  def pace_seconds_at_pct(vo2max, pct)
    velocity = velocity_at_vo2(vo2max * pct)
    (60_000.0 / velocity).round
  end
end
