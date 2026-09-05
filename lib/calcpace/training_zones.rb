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

  # Time spent in one heart-rate zone: the zone number, whole seconds, and the
  # fraction of the counted time that fell in it
  TimeInZone = Struct.new(:zone, :seconds, :share)

  # Shares are kept as thousandths while they are rounded, so that the five of
  # them can be made to add up to exactly 1.0 before they become Floats
  SHARE_UNITS = 1000

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

  # Finds the training zone a heart-rate reading belongs to
  #
  # The zones handed in are contiguous, so their boundaries are shared: 114 bpm
  # is both the top of zone 1 and the bottom of zone 2. The higher zone wins,
  # the way a watch reads it. Readings outside the range are clamped — below
  # zone 1 counts as zone 1, above zone 5 as zone 5 — because a reading above
  # hr_max means the hr_max is wrong, not that the beat did not happen.
  #
  # A `between?` lookup written against the zone bounds does neither: it gives a
  # boundary to the lower zone and returns nothing at all above hr_max.
  #
  # @param bpm [Numeric, nil] the reading in beats per minute
  # @param zones [Array<HrZone>] the zones from #hr_zones or #hr_zones_from_max
  # @return [HrZone, nil] the zone holding the reading; nil only when bpm is nil
  #   or not positive, which is what a sensor dropout looks like
  # @raise [Calcpace::Error] if bpm is neither nil nor Numeric, or zones is empty
  #
  # @example
  #   calc.hr_zone_for(150, calc.hr_zones_from_max(hr_max: 190)).zone #=> 3
  #   calc.hr_zone_for(114, calc.hr_zones_from_max(hr_max: 190)).zone #=> 2
  #   calc.hr_zone_for(80, calc.hr_zones_from_max(hr_max: 190)).zone  #=> 1
  #   calc.hr_zone_for(205, calc.hr_zones_from_max(hr_max: 190)).zone #=> 5
  def hr_zone_for(bpm, zones)
    index = hr_zone_index(bpm, zones)

    index && zones[index]
  end

  # Splits a recorded heart-rate series into the time spent in each zone
  #
  # Format-agnostic on purpose: two plain arrays and the zones to sort them
  # into. A Strava `heartrate`/`time` stream pair fits without translation, and
  # so does the same pair read out of a FIT file.
  #
  # A sample lasts until the next one — <tt>time[i + 1] - time[i]</tt> — and the
  # last sample, which has no next, is given the previous delta so that a series
  # does not lose its final seconds. A single sample therefore lasts 0 s.
  #
  # That rule has one consequence worth knowing before trusting the numbers: a
  # **pause is a gap in `time`, and the whole gap is booked to the sample before
  # it**. Stop for five minutes at a café and those five minutes land in
  # whatever zone the last beat before the pause was in. There is no max_gap
  # here to guess a cut-off with. A caller who has Strava's `moving` stream
  # should nil the heart rate of every paused sample before calling, which is
  # exactly what the next rule then does with them.
  #
  # A sample with a nil or non-positive heart rate contributes nothing at all:
  # its duration is dropped, never handed to a neighbour, because a dropout says
  # nothing about which zone the runner was in. So the counted time can be less
  # than the wall clock, and the shares are shares of what was counted.
  #
  # Readings outside the zones are clamped and boundaries go to the higher zone,
  # exactly as #hr_zone_for describes — an hr_max that is a few beats wrong is
  # the most common thing an athlete carries around, and clamping keeps that a
  # distortion of the split instead of making minutes of a run vanish.
  #
  # @param heartrate [Array<Numeric, nil>] heart rate in bpm, one entry per sample
  # @param time [Array<Numeric>] seconds since the start, non-decreasing, same length
  # @param zones [Array<HrZone>] the five zones from #hr_zones or #hr_zones_from_max
  # @return [Array<TimeInZone>] one row per zone in zone order, zeros included;
  #   seconds are Integer, shares Float with 3 decimals summing to exactly 1.0
  #   over the counted time (all zero when nothing was counted)
  # @raise [Calcpace::Error] if either series is not an Array, if they differ in
  #   length, if time holds a non-numeric entry or goes backwards, if a heart
  #   rate is neither nil nor Numeric, or if zones is empty
  #
  # @example four minutes of a run against zones for a 190 bpm maximum
  #   zones = calc.hr_zones_from_max(hr_max: 190)
  #   in_zones = calc.time_in_zones(heartrate: [120, 120, 140, 140, 160],
  #                                 time: [0, 60, 120, 180, 240],
  #                                 zones: zones)
  #   in_zones.map(&:seconds) #=> [0, 120, 120, 60, 0]
  #   in_zones.map(&:share)   #=> [0.0, 0.4, 0.4, 0.2, 0.0]
  #   in_zones[1].zone        #=> 2
  def time_in_zones(heartrate:, time:, zones:)
    check_hr_series(heartrate, time, zones)

    totals = zone_seconds(heartrate, time, zones)
    shares = zone_shares(totals)

    zones.each_with_index.map do |zone, index|
      TimeInZone.new(zone: zone.zone, seconds: totals[index].round, share: shares[index])
    end
  end

  private

  # @return [Array<Float>] seconds accumulated in each zone, in zone order
  def zone_seconds(heartrate, time, zones)
    totals = Array.new(zones.size, 0.0)

    heartrate.each_with_index do |bpm, index|
      zone = hr_zone_index(bpm, zones)
      next if zone.nil?

      totals[zone] += sample_duration(time, index)
    end

    totals
  end

  # Rounded on its own each share is out by up to half a thousandth, and five of
  # those leave a bar chart that does not fill its track. Largest-remainder
  # rounding spends the residue on the zones that lost the most to rounding, so
  # the shares add up to exactly 1.0. Ties go to the earlier zone, so the same
  # series always splits the same way.
  def zone_shares(totals)
    counted = totals.sum
    return Array.new(totals.size, 0.0) unless counted.positive?

    scaled = totals.map { |seconds| seconds * SHARE_UNITS / counted }
    units = scaled.map(&:floor)
    largest_remainders(scaled, units, SHARE_UNITS - units.sum).each { |index| units[index] += 1 }

    units.map { |unit| unit / SHARE_UNITS.to_f }
  end

  # @return [Array<Integer>] the indexes that give up the most to rounding down
  def largest_remainders(scaled, units, residue)
    return [] unless residue.positive?

    scaled.each_index.sort_by { |index| [units[index] - scaled[index], index] }.first(residue)
  end

  # The last sample has no successor, so it inherits the previous delta
  def sample_duration(time, index)
    last = time.size - 1
    return 0.0 if last.zero?

    from = index == last ? last - 1 : index
    (time[from + 1] - time[from]).to_f
  end

  # The highest zone the reading reaches, clamped to zone 1 below the bottom
  def hr_zone_index(bpm, zones)
    check_zones(zones)
    return nil if bpm.nil?

    raise Calcpace::Error, "Heart rate must be numeric or nil (got #{bpm.inspect})" unless bpm.is_a?(Numeric)

    bpm.positive? ? (zones.rindex { |zone| bpm >= zone.min_bpm } || 0) : nil
  end

  def check_hr_series(heartrate, time, zones)
    unless heartrate.is_a?(Array) && time.is_a?(Array)
      raise Calcpace::Error, 'Heart rate and time series must both be arrays'
    end
    raise Calcpace::Error, 'Heart rate and time series must have the same length' if heartrate.size != time.size

    check_zones(zones)
    check_time_series(time)
  end

  # A nil in the middle of the time stream is not a zero-length sample — it is a
  # stream we cannot measure any duration from, so it is an error, not a drop
  def check_time_series(time)
    time.each do |seconds|
      raise Calcpace::Error, "Every time entry must be numeric (got #{seconds.inspect})" unless seconds.is_a?(Numeric)
    end

    raise Calcpace::Error, 'Time series must be non-decreasing' if time.each_cons(2).any? { |a, b| b < a }
  end

  def check_zones(zones)
    raise Calcpace::Error, 'At least one heart-rate zone is required' if zones.nil? || zones.empty?
  end

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
