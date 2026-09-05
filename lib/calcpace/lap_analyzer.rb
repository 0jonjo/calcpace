# frozen_string_literal: true

# Module for reading the shape of a session out of its laps
#
# A watch records laps; it does not record intent. Nothing in the data says
# "6 × 1 km", and the label a runner typed into an app is not evidence — most
# sessions carry none, and the ones that do are often wrong. What is always in
# the data is **contrast**: a rep is a lap that is much faster than the laps
# touching it, and the recovery between two reps is the lap that is not.
#
# So the detection here is purely relative. A lap is work when it is at least
# WORK_PACE_RATIO faster than every lap beside it; everything before the first
# work lap is warm-up, everything after the last is cool-down, and what sits
# between two work laps is rest. A session is only called structured when the
# reps agree with each other on distance — otherwise it is a fartlek or a hilly
# run, which has fast laps but no structure to report.
#
# Format-agnostic by design: laps are plain hashes of a distance in kilometres
# and an elapsed time in seconds, which is what a Strava lap, a FIT lap and a
# hand-written array all reduce to.
module LapAnalyzer
  # A detected interval session. Paces are seconds per unit, distances km.
  IntervalStructure = Struct.new(:reps, :work_distance, :work_pace, :rest_pace, :rest_duration)

  # One lap reduced to the three numbers the detection reasons about
  LapPace = Struct.new(:distance, :elapsed, :pace)

  # How much faster than its neighbours a lap must be to count as work
  WORK_PACE_RATIO = 0.85

  # Below this a lap is a split, not a rep — a hand-pressed button, a GPS
  # hiccup, the last metres of a track lap recorded on their own
  MIN_WORK_DISTANCE_KM = 0.1

  # How far a rep may sit from the median rep distance and still belong to the
  # same set. Wider than this and the fast laps are not one workout
  WORK_DISTANCE_TOLERANCE = 0.25

  # How much slower than the reps found in the interior an edge lap may be and
  # still be read as one of them. A warm-up or cool-down only ever has one
  # neighbour, so contrast alone would let it in on beating a single jog
  EDGE_PACE_TOLERANCE = 1.10

  # A lap longer than this was measured in metres by a caller who thinks they
  # are kilometres. No lap of a running session is 100 km
  MAX_LAP_DISTANCE_KM = 100

  # Detects a structured interval session in a list of laps
  #
  # Returns nil whenever the laps do not describe one: a steady run, a single
  # hard effort, a fartlek whose surges have nothing in common. Nil is the
  # honest answer — most runs are not intervals, and inventing reps out of
  # ordinary pace variation would make every easy run look like a workout.
  #
  # @param laps [Array<Hash>] laps in order, each with :distance in kilometres
  #   (Numeric, 0 up to 100, and 0 means a standing recovery) and :elapsed in
  #   seconds (Numeric, must be positive). String keys are accepted too
  # @param unit [Symbol, String] unit of the returned paces — :km (default) or :mi.
  #   Distances stay in kilometres in both
  # @return [IntervalStructure, nil] nil when the laps have no structure, else a
  #   struct of: reps, the number of work laps; work_distance, their median
  #   distance in km rounded to 2 decimals; work_pace, their distance-weighted
  #   pace (total elapsed over total distance) in seconds per unit, rounded;
  #   rest_pace, the same over the rest laps, or nil when they covered no
  #   distance; and rest_duration, the mean rest lap in whole seconds
  # @raise [Calcpace::Error] if a lap is missing :distance or :elapsed, its
  #   distance is negative or over 100 km, or its elapsed time is not positive
  # @raise [Calcpace::UnsupportedUnitError] if unit is not :km or :mi
  #
  # @example warm-up, 6 × (1 km hard / 400 m jog), cool-down
  #   laps = [{ distance: 2.0, elapsed: 720 }] +
  #          ([{ distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 156 }] * 6) +
  #          [{ distance: 1.5, elapsed: 495 }]
  #   structure = calc.interval_structure(laps)
  #   structure.reps          #=> 6
  #   structure.work_distance #=> 1.0
  #   structure.work_pace     #=> 252
  #   structure.rest_pace     #=> 390
  #   structure.rest_duration #=> 156
  #
  # @example the smallest session that has a structure, every field at once
  #   calc.interval_structure([{ distance: 1.0, elapsed: 252 },
  #                            { distance: 0.4, elapsed: 156 },
  #                            { distance: 1.0, elapsed: 252 }]).to_a
  #   #=> [2, 1.0, 252, 390, 156]
  #
  # @example the same session with paces per mile
  #   calc.interval_structure(laps, unit: :mi).work_pace #=> 406
  #
  # @example a steady 10 km, ten laps of 1 km within five seconds of each other
  #   steady = [300, 298, 302, 296, 304, 300, 299, 301, 305, 295].map do |elapsed|
  #     { distance: 1.0, elapsed: elapsed }
  #   end
  #   calc.interval_structure(steady) #=> nil
  def interval_structure(laps, unit: :km)
    meters = pace_unit_meters(unit)
    parsed = parse_laps(laps)
    work = work_lap_indexes(parsed)
    return nil unless structured?(parsed, work)

    build_interval_structure(parsed, work, meters)
  end

  private

  # @param laps [Array<Hash>] raw laps
  # @return [Array<LapPace>] the same laps with their pace in seconds per km
  def parse_laps(laps)
    Array(laps).map do |lap|
      distance = lap_value(lap, :distance)
      elapsed = lap_value(lap, :elapsed)
      check_lap(distance, elapsed)

      LapPace.new(distance: distance, elapsed: elapsed,
                  pace: distance.positive? ? elapsed / distance : Float::INFINITY)
    end
  end

  # @raise [Calcpace::Error] if the key is missing or does not hold a number
  def lap_value(lap, key)
    value = lap.is_a?(Hash) ? (lap[key] || lap[key.to_s]) : nil
    return value.to_f if value.is_a?(Numeric)

    raise Calcpace::Error, "Every lap needs a numeric :#{key} (got #{value.inspect})"
  end

  def check_lap(distance, elapsed)
    raise Calcpace::Error, "Lap distance cannot be negative (got #{distance})" if distance.negative?
    raise Calcpace::Error, "Lap elapsed time must be positive (got #{elapsed})" unless elapsed.positive?
    return if distance <= MAX_LAP_DISTANCE_KM

    raise Calcpace::Error, "Lap distance #{distance} is too long — lap distances are kilometres, not metres"
  end

  # Interior laps are judged on contrast alone. An edge lap — the first or the
  # last — has only one neighbour, so contrast is a free pass: a cool-down beats
  # the jog it happens to touch and walks in as an extra rep, or as a rep of the
  # wrong length that makes the whole session look unstructured. It is admitted
  # only if it also looks like the reps already found in the middle.
  #
  # When the interior found nothing there is nothing to agree with, so the plain
  # contrast rule stands and the three-lap session (work, rest, work) still reads.
  #
  # @return [Array<Integer>] indexes of the laps that stand out as reps
  def work_lap_indexes(laps)
    interior = (1...(laps.size - 1)).select { |index| work_lap?(laps, index) }
    return laps.each_index.select { |index| work_lap?(laps, index) } if interior.empty?

    edges = [0, laps.size - 1].uniq.select do |index|
      work_lap?(laps, index) && matches_interior?(laps, index, interior)
    end

    (interior + edges).sort
  end

  def matches_interior?(laps, index, interior)
    lap = laps[index]
    median = median(interior.map { |i| laps[i].distance })

    (lap.distance - median).abs <= WORK_DISTANCE_TOLERANCE * median &&
      lap.pace <= EDGE_PACE_TOLERANCE * weighted_pace(laps, interior)
  end

  # Two work laps can never touch: each would have to be 0.85 of the other.
  # That is what guarantees a rest lap between every pair of reps.
  def work_lap?(laps, index)
    lap = laps[index]
    return false if lap.distance < MIN_WORK_DISTANCE_KM

    neighbour_paces(laps, index).all? { |pace| lap.pace <= WORK_PACE_RATIO * pace }
  end

  def neighbour_paces(laps, index)
    [index - 1, index + 1].select { |i| i >= 0 && i < laps.size }
                          .map { |i| laps[i].pace }
  end

  def structured?(laps, work)
    return false if work.size < 2
    return false unless beat_a_real_pace?(laps, work)

    distances = work.map { |index| laps[index].distance }
    median = median(distances)

    distances.all? { |distance| (distance - median).abs <= WORK_DISTANCE_TOLERANCE * median }
  end

  # A lap of zero distance has an infinite pace, and everything is 15% faster
  # than infinity. So an easy run with two red-light lap presses looks exactly
  # like three reps around two standing recoveries. At least one rep has to have
  # beaten a pace that was actually run; otherwise the contrast is an artefact
  # of the pauses and there is no evidence of a workout at all.
  def beat_a_real_pace?(laps, work)
    work.any? { |index| neighbour_paces(laps, index).any?(&:finite?) }
  end

  def build_interval_structure(laps, work, meters)
    rest = rest_lap_indexes(work)

    IntervalStructure.new(
      reps: work.size,
      work_distance: median(work.map { |index| laps[index].distance }).round(2),
      work_pace: converted_pace(weighted_pace(laps, work), meters),
      rest_pace: converted_pace(weighted_pace(laps, rest), meters),
      rest_duration: rest.empty? ? nil : mean(rest.map { |index| laps[index].elapsed }).round
    )
  end

  # Laps sitting between two consecutive reps. Anything outside the reps is
  # warm-up or cool-down, which is not part of the session's structure.
  #
  # Never empty in practice once there are two reps, because two work laps can
  # never be adjacent — but reps and rest are counted separately here so that a
  # change to the work rule shows up as a nil field, not as a NaN.
  def rest_lap_indexes(work)
    work.each_cons(2).flat_map { |from, to| ((from + 1)...to).to_a }
  end

  # Distance-weighted pace, so a longer rep counts for more than a short one.
  # Nil when the laps covered no distance at all — a standing recovery has a
  # duration but no pace, and reporting infinity would be worse than reporting
  # nothing.
  def weighted_pace(laps, indexes)
    distance = indexes.sum { |index| laps[index].distance }
    return nil unless distance.positive?

    indexes.sum { |index| laps[index].elapsed } / distance
  end

  def converted_pace(pace_per_km, meters)
    return nil if pace_per_km.nil?

    (pace_per_km * meters / 1000.0).round
  end

  def median(values)
    sorted = values.sort
    middle = sorted.size / 2

    sorted.size.odd? ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2.0
  end

  def mean(values)
    values.sum / values.size.to_f
  end
end
