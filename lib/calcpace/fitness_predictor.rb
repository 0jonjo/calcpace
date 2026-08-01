# frozen_string_literal: true

# Module for predicting race performances from a VO2max value
#
# This is the inverse of Vo2maxEstimator#estimate_vo2max: instead of asking
# "what fitness does this race result imply?", it asks "what race result does
# this fitness imply?".
#
# The Daniels & Gilbert (1979) model cannot be inverted in closed form — the
# %VO2max term mixes two exponentials of time with a quadratic in velocity —
# so the finish time is found by bisection on the time axis. VO2max decreases
# monotonically with time for a fixed distance, which makes the search exact
# to within the tolerance and guarantees the round trip:
#
#   estimate_vo2max(distance, predict_time_from_vo2max(vo2max, distance)) == vo2max
#
# Predicted times reproduce Daniels' published VDOT table within a few seconds
# for the shorter races and about a minute for the marathon.
module FitnessPredictor
  # Range of VO2max values the model is meaningful for. Below it the effort is
  # slower than a walk, above it faster than any human has run — in both cases
  # the resulting "prediction" would be arithmetic, not physiology.
  SUPPORTED_VO2MAX_RANGE = (10.0..100.0)

  # Bisection bounds, as seconds per kilometre: from 1:00/km (well beyond world
  # record pace) to 20:00/km (slower than walking). They bracket every VO2max
  # in SUPPORTED_VO2MAX_RANGE at any distance.
  FASTEST_PACE_SECONDS_PER_KM = 60.0
  SLOWEST_PACE_SECONDS_PER_KM = 1200.0

  # Search stops when the bracket is tighter than this many seconds or when the
  # VO2max at the midpoint is this close to the target
  TIME_TOLERANCE_SECONDS = 0.001
  VO2MAX_TOLERANCE = 1e-6

  # Races reported by #race_times_from_vo2max when none are given
  DEFAULT_RACES = %w[5k 10k half_marathon marathon].freeze

  # Predicts the finish time a given VO2max is worth over a given race
  #
  # @param vo2max [Numeric] VO2max in ml/kg/min (must be within SUPPORTED_VO2MAX_RANGE)
  # @param race [Numeric, String, Symbol] race distance in kilometres (or in
  #   miles via distance_unit: :mi), either numeric or as a numeric string
  #   ('10', '21.0975'), or a standard race name ('5k', '10k', 'half_marathon',
  #   'marathon', '1mile', '5mile', '10mile', '100k' — see
  #   PaceCalculator::RACE_DISTANCES)
  # @param distance_unit [Symbol, nil] unit of a numeric race distance — :km
  #   (default) or :mi. Rejected when race is a race name: standard races
  #   already carry their own distance
  # @return [Float] predicted finish time in seconds
  # @raise [Calcpace::NonPositiveInputError] if vo2max or distance are not positive
  # @raise [ArgumentError] if vo2max is outside the supported range, if a race
  #   name is not recognized, or if distance_unit is combined with a race name
  # @raise [Calcpace::UnsupportedUnitError] if distance_unit is not :km or :mi
  #
  # @example
  #   calc.predict_time_from_vo2max(50, '5k')       #=> 1196.02 (≈19:56)
  #   calc.predict_time_from_vo2max(50, 'marathon') #=> 11439.74 (≈3:10:39)
  #   calc.predict_time_from_vo2max(50, 6.2, distance_unit: :mi)
  def predict_time_from_vo2max(vo2max, race, distance_unit: nil)
    target = validated_vo2max(vo2max)
    distance_km = predicted_race_distance_km(race, distance_unit)
    check_positive(distance_km, 'Distance')

    solve_time_for_vo2max(target, distance_km)
  end

  # Predicts the finish time and returns it as a clock time string
  #
  # @param (see #predict_time_from_vo2max)
  # @return [String] predicted finish time in HH:MM:SS format
  #
  # @example
  #   calc.predict_time_from_vo2max_clock(50, 'marathon') #=> '03:10:39'
  def predict_time_from_vo2max_clock(vo2max, race, distance_unit: nil)
    convert_to_clocktime(predict_time_from_vo2max(vo2max, race, distance_unit: distance_unit))
  end

  # Builds a full race-time table for one VO2max — one call per dashboard
  #
  # @param vo2max [Numeric] VO2max in ml/kg/min
  # @param races [Array<String, Symbol>, nil] race names to report
  #   (default: 5k, 10k, half marathon, marathon)
  # @param unit [Symbol] unit of the returned paces — :km (default) or :mi
  # @return [Hash{String => Hash}] race name => { time: seconds,
  #   time_clock: 'HH:MM:SS', pace: seconds per unit, pace_clock: 'HH:MM:SS' }
  # @raise [ArgumentError] if a race name is not recognized or vo2max is out of range
  # @raise [Calcpace::NonPositiveInputError] if vo2max is not positive
  # @raise [Calcpace::UnsupportedUnitError] if unit is not :km or :mi
  #
  # @example
  #   calc.race_times_from_vo2max(50)['10k']
  #   #=> { time: 2479.6, time_clock: '00:41:19', pace: 247.96, pace_clock: '00:04:07' }
  #   calc.race_times_from_vo2max(50, races: %w[5k 10mile], unit: :mi)
  def race_times_from_vo2max(vo2max, races: nil, unit: :km)
    meters = pace_unit_meters(unit)
    validated_vo2max(vo2max)

    Array(races || DEFAULT_RACES).to_h do |race|
      [normalize_race_key(race), race_time_entry(vo2max, race, meters)]
    end
  end

  private

  def race_time_entry(vo2max, race, meters)
    seconds = predict_time_from_vo2max(vo2max, race)
    pace = seconds / (race_distance(race) * Converter::Distance::KM_TO_METERS / meters)

    {
      time: seconds,
      time_clock: convert_to_clocktime(seconds),
      pace: pace,
      pace_clock: convert_to_clocktime(pace)
    }
  end

  # Same distance semantics as TrainingZones#training_paces_from_race: numeric
  # strings ('10') stay distances, only race names fall through to the lookup
  def predicted_race_distance_km(race, distance_unit)
    numeric = race.is_a?(Numeric) ? race : Float(race, exception: false)
    return normalize_distance_km(numeric, distance_unit || :km) if numeric

    reject_distance_unit_with_race_name!(distance_unit, race)
    race_distance(race)
  end

  def validated_vo2max(vo2max)
    value = vo2max.to_f
    check_positive(value, 'VO2max')
    return value if SUPPORTED_VO2MAX_RANGE.cover?(value)

    raise ArgumentError,
          "VO2max #{value} is outside the supported range " \
          "(#{SUPPORTED_VO2MAX_RANGE.min}–#{SUPPORTED_VO2MAX_RANGE.max} ml/kg/min)"
  end

  # Bisects the time axis for the finish time whose VO2max equals the target
  def solve_time_for_vo2max(target, distance_km)
    low = distance_km * FASTEST_PACE_SECONDS_PER_KM
    high = distance_km * SLOWEST_PACE_SECONDS_PER_KM
    ensure_vo2max_reachable!(target, distance_km, low, high)

    while high - low > TIME_TOLERANCE_SECONDS
      mid = (low + high) / 2.0
      value = raw_vo2max(distance_km, mid)
      return mid.round(2) if (value - target).abs < VO2MAX_TOLERANCE

      # Faster (lower) times mean a higher VO2max, so the target sits below mid
      value > target ? low = mid : high = mid
    end

    ((low + high) / 2.0).round(2)
  end

  # Defensive bracket check: the search bounds cover the whole supported range
  # at every distance, so this only fires if those constants are ever widened
  def ensure_vo2max_reachable!(target, distance_km, low, high)
    reachable = raw_vo2max(distance_km, high)..raw_vo2max(distance_km, low)
    return if reachable.cover?(target)

    raise ArgumentError,
          "VO2max #{target} is not reachable over #{distance_km} km within the search bounds " \
          "(#{reachable.min.round(1)}–#{reachable.max.round(1)} ml/kg/min)"
  end

  # Unrounded Daniels & Gilbert VO2max for a distance/time pair. The public
  # #estimate_vo2max rounds to one decimal, which turns the curve into steps
  # and would cap the round-trip accuracy at the size of a step.
  def raw_vo2max(distance_km, seconds)
    time_min = seconds / 60.0
    velocity = distance_km * Converter::Distance::KM_TO_METERS / time_min

    vo2_at_velocity(velocity) / percent_vo2max(time_min)
  end
end
