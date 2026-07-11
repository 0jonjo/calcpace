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

  # Heart-rate zone boundaries as fractions of Heart Rate Reserve (Karvonen)
  HR_ZONE_BOUNDARIES = [0.50, 0.60, 0.70, 0.80, 0.90, 1.00].freeze

  # One heart-rate training zone (1 = recovery … 5 = maximal)
  HrZone = Struct.new(:zone, :min_bpm, :max_bpm)

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

  # Derives training pace bands from a recent race result
  #
  # Convenience wrapper: estimates VO2max via Daniels & Gilbert
  # (see Vo2maxEstimator#estimate_vo2max) and derives the bands from it.
  #
  # @param distance_km [Numeric] race distance in kilometres (must be > 0)
  # @param time [String, Integer] finish time as "HH:MM:SS" / "MM:SS" or total seconds
  # @return [Hash{Symbol => PaceBand}] same shape as #training_paces
  # @raise [Calcpace::NonPositiveInputError] if distance or time are not positive
  # @raise [Calcpace::InvalidTimeFormatError] if time string is malformed
  #
  # @example
  #   calc.training_paces_from_race(10.0, '00:40:00')[:easy].slow_clock #=> "00:05:42"
  def training_paces_from_race(distance_km, time)
    training_paces(estimate_vo2max(distance_km, time))
  end

  # Computes the five Karvonen heart-rate training zones
  #
  # target_bpm = hr_rest + pct * (hr_max - hr_rest)
  #
  # @param hr_max [Numeric] maximum heart rate in bpm (must be > 0)
  # @param hr_rest [Numeric] resting heart rate in bpm (must be > 0 and < hr_max)
  # @return [Array<HrZone>] five contiguous zones from Z1 (50–60% HRR) to Z5 (90–100% HRR)
  # @raise [Calcpace::NonPositiveInputError] if any rate is not positive
  # @raise [Calcpace::Error] if hr_rest >= hr_max
  #
  # @example
  #   calc.hr_zones(hr_max: 190, hr_rest: 55).last.max_bpm #=> 190
  def hr_zones(hr_max:, hr_rest:)
    max  = hr_max.to_f
    rest = hr_rest.to_f
    check_heart_rates(max, rest)

    reserve = max - rest
    points  = HR_ZONE_BOUNDARIES.map { |pct| (rest + (pct * reserve)).round }

    points.each_cons(2).with_index(1).map do |(min_bpm, max_bpm), zone|
      HrZone.new(zone: zone, min_bpm: min_bpm, max_bpm: max_bpm)
    end
  end

  private

  def check_heart_rates(hr_max, hr_rest)
    check_positive(hr_max, 'Maximum heart rate')
    check_positive(hr_rest, 'Resting heart rate')
    return if hr_rest < hr_max

    raise Calcpace::Error,
          "Resting heart rate (#{hr_rest}) must be lower than maximum heart rate (#{hr_max})"
  end

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
