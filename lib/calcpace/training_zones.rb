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

  # A pace band for one training zone (paces per kilometre or mile).
  # slow = lower-intensity end of the band, fast = higher-intensity end.
  PaceBand = Struct.new(:slow_seconds, :fast_seconds, :slow_clock, :fast_clock)

  # Metres per pace unit — pace bands can be expressed per km or per mile
  PACE_UNIT_METERS = { km: 1000.0, mi: Converter::Distance::MI_TO_METERS }.freeze

  # Heart-rate zone boundaries as fractions of the range being split:
  # Heart Rate Reserve in #hr_zones (Karvonen) and HRmax in #hr_zones_from_max
  HR_ZONE_BOUNDARIES = [0.50, 0.60, 0.70, 0.80, 0.90, 1.00].freeze

  # One heart-rate training zone (1 = recovery … 5 = maximal)
  HrZone = Struct.new(:zone, :min_bpm, :max_bpm)

  # Derives training pace bands from a VO2max value
  #
  # @param vo2max [Numeric] VO2max in ml/kg/min (must be > 0)
  # @param unit [Symbol] pace unit — :km (default) or :mi
  # @return [Hash{Symbol => PaceBand}] keys: :easy, :marathon, :threshold,
  #   :interval, :repetition — paces per chosen unit
  # @raise [Calcpace::NonPositiveInputError] if vo2max is not positive
  # @raise [Calcpace::UnsupportedUnitError] if unit is not :km or :mi
  #
  # @example
  #   calc.training_paces(50.0)[:threshold].fast_clock             #=> "00:04:15"
  #   calc.training_paces(50.0, unit: :mi)[:threshold].fast_clock  #=> "00:06:51"
  def training_paces(vo2max, unit: :km)
    check_positive(vo2max.to_f, 'VO2max')
    meters = pace_unit_meters(unit)

    TRAINING_INTENSITIES.transform_values do |band|
      slow = pace_seconds_at_pct(vo2max.to_f, band[:low], meters)
      fast = pace_seconds_at_pct(vo2max.to_f, band[:high], meters)

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
  # @param race [Numeric, String, Symbol] race distance in kilometres (or in
  #   miles via distance_unit: :mi), either numeric or as a numeric string
  #   ('10', '21.0975'), or a standard race name ('5k', '10k', 'half_marathon',
  #   'marathon', '1mile', '5mile', '10mile', '100k' — see
  #   PaceCalculator::RACE_DISTANCES)
  # @param time [String, Integer] finish time as "HH:MM:SS" / "MM:SS" or total seconds
  # @param unit [Symbol] pace unit of the output bands — :km (default) or :mi
  # @param distance_unit [Symbol] unit of a numeric race distance input — :km (default) or :mi.
  #   Rejected when race is a race name: standard races already carry their own
  #   distance, so the combination is always a caller mistake
  # @return [Hash{Symbol => PaceBand}] same shape as #training_paces
  # @raise [ArgumentError] if a race name is not recognized, or if distance_unit
  #   is combined with a race name
  # @raise [Calcpace::UnsupportedUnitError] if unit or distance_unit is not :km or :mi
  # @raise [Calcpace::NonPositiveInputError] if distance or time are not positive
  # @raise [Calcpace::InvalidTimeFormatError] if time string is malformed
  #
  # @example
  #   calc.training_paces_from_race(10.0, '00:40:00')[:easy].slow_clock #=> "00:05:42"
  #   calc.training_paces_from_race('5mile', '00:35:00', unit: :mi)
  #   calc.training_paces_from_race(6.2, '00:40:00', distance_unit: :mi, unit: :mi)
  def training_paces_from_race(race, time, unit: :km, distance_unit: nil)
    # Numeric strings ('10') keep working as distances; only non-numeric input
    # (race names) falls through to the RACE_DISTANCES lookup
    numeric = race.is_a?(Numeric) ? race : Float(race, exception: false)
    distance_km = if numeric
                    normalize_distance_km(numeric, distance_unit || :km)
                  else
                    reject_distance_unit_with_race_name!(distance_unit, race)
                    race_distance(race)
                  end

    training_paces(estimate_vo2max(distance_km, time), unit: unit)
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
    build_hr_zones(HR_ZONE_BOUNDARIES.map { |pct| (rest + (pct * reserve)).round })
  end

  # Computes five heart-rate zones from maximum heart rate only (%HRmax method)
  #
  # Fallback for athletes who don't know their resting heart rate — the
  # classic percent-of-max model used as default by most sports watches:
  #   target_bpm = pct * hr_max
  #
  # Prefer #hr_zones (Karvonen) when resting heart rate is available.
  #
  # @param hr_max [Numeric] maximum heart rate in bpm (must be > 0)
  # @return [Array<HrZone>] five contiguous zones from Z1 (50–60% HRmax) to Z5 (90–100% HRmax)
  # @raise [Calcpace::NonPositiveInputError] if hr_max is not positive
  #
  # @example
  #   calc.hr_zones_from_max(hr_max: 190).first.min_bpm #=> 95
  def hr_zones_from_max(hr_max:)
    max = hr_max.to_f
    check_positive(max, 'Maximum heart rate')

    build_hr_zones(HR_ZONE_BOUNDARIES.map { |pct| (pct * max).round })
  end

  private

  # Turns six ascending bpm boundary points into five contiguous HrZone structs
  def build_hr_zones(points)
    points.each_cons(2).with_index(1).map do |(min_bpm, max_bpm), zone|
      HrZone.new(zone: zone, min_bpm: min_bpm, max_bpm: max_bpm)
    end
  end

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

  def pace_unit_meters(unit)
    PACE_UNIT_METERS.fetch(unit.to_s.downcase.to_sym) do
      raise Calcpace::UnsupportedUnitError.new(unit, supported: PACE_UNIT_METERS.keys)
    end
  end

  def pace_seconds_at_pct(vo2max, pct, meters)
    velocity = velocity_at_vo2(vo2max * pct)
    (meters * 60.0 / velocity).round
  end
end
