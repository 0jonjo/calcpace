# frozen_string_literal: true

# Module for GPS track calculations
#
# This module provides pure mathematical methods for computing distances,
# elevation changes, and pace splits from arrays of GPS coordinate points.
# It does not perform any file I/O or GPX parsing — callers are responsible
# for supplying arrays of hashes with the required keys.
#
# @example Calculate total distance of a track
#   calc = Calcpace.new
#   points = [
#     { lat: -23.5505, lon: -46.6333 },
#     { lat: -23.5510, lon: -46.6340 },
#     { lat: -23.5520, lon: -46.6350 }
#   ]
#   calc.track_distance(points) #=> 0.24 (km)
#
# @example Calculate elevation gain and loss
#   points = [
#     { lat: -23.5505, lon: -46.6333, ele: 760.0 },
#     { lat: -23.5510, lon: -46.6340, ele: 763.5 },
#     { lat: -23.5515, lon: -46.6347, ele: 758.0 }
#   ]
#   calc.elevation_gain(points) #=> { gain: 3.5, loss: 5.5 }
module TrackCalculator
  # Mean radius of the Earth in kilometers (IAU standard)
  EARTH_RADIUS_KM = 6371.0

  # Shortest horizontal distance a grade is measured over in
  # #track_grade_adjusted_splits. GPS elevation is noisy — a few metres between
  # consecutive fixes even from a barometric altimeter — so a grade read
  # between points 1 m apart can be ±300% on flat ground, and the grade factor's
  # curvature turns that symmetric noise into a fake climb. Over 100 m, ±1–2 m
  # of noise is ±1–2% of grade, while a hill longer than a track straight still
  # shows up.
  GRADE_SEGMENT_MIN_KM = 0.1

  # Slack on GRADE_SEGMENT_MIN_KM so ten 10 m steps, which sum to a hair under
  # 0.1 km in floating point, still close a 100 m grade segment (1 mm)
  GRADE_SEGMENT_TOLERANCE_KM = 1e-6

  # Computes the great-circle distance between two GPS coordinates using
  # the Haversine formula.
  #
  # The Haversine formula calculates the shortest distance over the Earth's
  # surface between two points defined by latitude and longitude. It assumes
  # a spherical Earth (error < 0.3% vs. WGS84 ellipsoid), which is accurate
  # enough for running and cycling purposes.
  #
  # Formula:
  #   a = sin²(Δlat/2) + cos(lat1) × cos(lat2) × sin²(Δlon/2)
  #   c = 2 × atan2(√a, √(1−a))
  #   d = R × c
  #
  # @param lat1 [Numeric] latitude of first point in decimal degrees
  # @param lon1 [Numeric] longitude of first point in decimal degrees
  # @param lat2 [Numeric] latitude of second point in decimal degrees
  # @param lon2 [Numeric] longitude of second point in decimal degrees
  # @return [Float] distance in kilometers
  # @raise [ArgumentError] if any coordinate is outside valid range (lat ±90, lon ±180)
  #
  # @example Distance between two points in São Paulo
  #   haversine_distance(-23.5505, -46.6333, -23.5510, -46.6340)
  #   #=> 0.09045636644035066 (km)
  def haversine_distance(lat1, lon1, lat2, lon2)
    validate_coordinates(lat1, lon1)
    validate_coordinates(lat2, lon2)
    haversine_km(lat1, lon1, lat2, lon2)
  end

  # Calculates the total distance of a GPS track by summing Haversine distances
  # between consecutive points.
  #
  # @param points [Array<Hash>] array of points with :lat and :lon keys (String or Symbol)
  # @return [Float] total distance in kilometers, rounded to 2 decimal places
  # @raise [ArgumentError] if any point has coordinates outside valid range
  #
  # @example
  #   points = [
  #     { lat: -23.5505, lon: -46.6333 },
  #     { lat: -23.5510, lon: -46.6340 },
  #     { lat: -23.5520, lon: -46.6350 }
  #   ]
  #   track_distance(points) #=> 0.24
  def track_distance(points)
    return 0.0 if points.nil? || points.size < 2

    total = points.each_cons(2).sum do |a, b|
      haversine_distance(dig_key(a, :lat), dig_key(a, :lon),
                         dig_key(b, :lat), dig_key(b, :lon))
    end

    total.round(2)
  end

  # Calculates cumulative elevation gain and loss along a GPS track.
  #
  # Only consecutive pairs where both points have an :ele value are considered.
  # Points missing :ele are silently skipped.
  #
  # @param points [Array<Hash>] array of points with optional :ele key (meters)
  # @return [Hash] hash with :gain and :loss keys, both Floats rounded to 1 decimal
  #
  # @example
  #   points = [
  #     { lat: 0, lon: 0, ele: 100.0 },
  #     { lat: 0, lon: 0, ele: 105.0 },
  #     { lat: 0, lon: 0, ele: 102.0 }
  #   ]
  #   elevation_gain(points) #=> { gain: 5.0, loss: 3.0 }
  def elevation_gain(points)
    gain = 0.0
    loss = 0.0
    return { gain: gain, loss: loss } if points.nil? || points.size < 2

    points.each_cons(2) do |a, b|
      gain, loss = accumulate_elevation(gain, loss, fetch_ele(a), fetch_ele(b))
    end

    { gain: gain.round(1), loss: loss.round(1) }
  end

  # Calculates pace splits at regular distance intervals along a GPS track.
  #
  # Accumulates Haversine distance between consecutive points until the target
  # split distance is reached, then records elapsed time and pace for that split.
  # Any remaining distance at the end is included as a partial split.
  #
  # Only :pace changes with compact: — :km and :elapsed are numbers, not
  # formatted strings, and are the same in both modes.
  #
  # The two pace formats differ by more than padding once a split is slower than
  # an hour per unit: the padded format keeps counting minutes ('66:33'), as it
  # always has, while the compact one rolls them into an hour field ('1:06:33'),
  # like every other compact duration in the gem. A track that steps backwards
  # in time (a watch clock resync, a paused device, merged segments) yields a
  # negative split, reported with a leading minus in both formats ('-00:40' /
  # '-0:40') rather than raising.
  #
  # @param points [Array<Hash>] array of points with :lat, :lon, and :time keys.
  #   :time must respond to #to_f (Unix timestamp) or be a Time object.
  # @param split_km [Numeric] split interval in kilometers (default: 1.0)
  # @param compact [Boolean] when true, :pace uses the compact display format
  # @return [Array<Hash>] array of split hashes, each with:
  #   - :km [Float] cumulative distance at split end
  #   - :elapsed [Integer] elapsed seconds from start of track to end of split
  #   - :pace [String] pace for this split in MM:SS format, or 'M:SS' / 'H:MM:SS'
  #     with compact: true
  # @raise [ArgumentError] if split_km is not positive
  # @raise [ArgumentError] if any point is missing a :time key
  #
  # @example 5 km track with 1 km splits
  #   calc.track_splits(points, 1.0)
  #   #=> [
  #         { km: 1.0, elapsed: 312, pace: "05:12" },
  #         { km: 2.0, elapsed: 624, pace: "05:12" },
  #         ...
  #       ]
  #
  # @example compact pace
  #   calc.track_splits(points, 1.0, compact: true)
  #   #=> [{ km: 1.0, elapsed: 312, pace: "5:12" }, ...]
  def track_splits(points, split_km = 1.0, compact: false)
    raise ArgumentError, 'split_km must be positive' unless split_km.is_a?(Numeric) && split_km.positive?
    return [] if points.nil? || points.size < 2

    validate_points_have_time(points)
    collect_splits(points, split_km, compact: compact)
  end

  # Pace splits with a grade-adjusted pace (GAP) for each split.
  #
  # Each split is the hash #track_splits returns — same :km, :elapsed and :pace,
  # split boundaries computed the same way — plus :gap, the flat-ground pace of
  # equal effort for that split (Minetti et al., 2002; see GradeAdjustedPace).
  # #track_splits itself is unchanged.
  #
  # How :gap is computed:
  # - The track is cut into grade segments of at least GRADE_SEGMENT_MIN_KM
  #   (100 m) of horizontal distance, and each gets one grade: its net
  #   elevation change over its length. A leftover shorter than that at the end
  #   of a stretch is merged into the segment before it. Grades are clamped to
  #   ±45%, the range the model was measured on.
  # - A stretch between points without :ele (or with a NaN/infinite one) is
  #   flat (factor 1.0), and a missing :ele ends the grade segment in progress.
  #   A stretch with elevation shorter than one grade segment and with no full
  #   segment before it to join — or a whole track that short — is flat too.
  # - Distances are the horizontal (Haversine) ones; the factor is applied to
  #   them as is, without the √(1 + grade²) slope correction (0.5% at 10%).
  # - Each split's distance is weighted by the grade factor of the segments it
  #   covers, and :gap is the split's time over that flat-equivalent distance.
  #   A split on flat ground, or with no elevation data, has :gap equal to :pace.
  #
  # @param points [Array<Hash>] points with :lat, :lon and :time keys, and
  #   optionally :ele (metres), as for #track_splits
  # @param split_km [Numeric] split interval in kilometers (default: 1.0)
  # @param compact [Boolean] when true, :pace and :gap use the compact display format
  # @return [Array<Hash>] split hashes with :km, :elapsed, :pace and :gap
  #   (:gap formatted like :pace)
  # @raise [ArgumentError] if split_km is not positive
  # @raise [ArgumentError] if any point is missing a :time key
  #
  # @example a steady 5% climb at 5:00/km
  #   calc.track_grade_adjusted_splits(points, 1.0)
  #   #=> [{ km: 1.0, elapsed: 300, pace: "05:00", gap: "03:51" }, ...]
  def track_grade_adjusted_splits(points, split_km = 1.0, compact: false)
    raise ArgumentError, 'split_km must be positive' unless split_km.is_a?(Numeric) && split_km.positive?
    return [] if points.nil? || points.size < 2

    validate_points_have_time(points)
    collect_splits(points, split_km, compact: compact, grade_factors: segment_grade_factors(points))
  end

  private

  def haversine_km(lat1, lon1, lat2, lon2)
    dlat = deg_to_rad(lat2 - lat1)
    dlon = deg_to_rad(lon2 - lon1)
    a = haversine_a(dlat, dlon, lat1, lat2)
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    EARTH_RADIUS_KM * c
  end

  def haversine_a(dlat, dlon, lat1, lat2)
    (Math.sin(dlat / 2)**2) +
      (Math.cos(deg_to_rad(lat1)) * Math.cos(deg_to_rad(lat2)) *
      (Math.sin(dlon / 2)**2))
  end

  def deg_to_rad(degrees)
    degrees * Math::PI / 180.0
  end

  def validate_coordinates(lat, lon)
    unless lat.is_a?(Numeric) && lat >= -90 && lat <= 90
      raise ArgumentError, "Invalid latitude: #{lat}. Must be between -90 and 90."
    end

    return if lon.is_a?(Numeric) && lon >= -180 && lon <= 180

    raise ArgumentError, "Invalid longitude: #{lon}. Must be between -180 and 180."
  end

  def accumulate_elevation(gain, loss, ele_a, ele_b)
    return [gain, loss] if ele_a.nil? || ele_b.nil?

    diff = ele_b - ele_a
    if diff.positive?
      [gain + diff, loss]
    else
      [gain, loss + diff.abs]
    end
  end

  def dig_key(point, key)
    point[key] || point[key.to_s]
  end

  def fetch_ele(point)
    dig_key(point, :ele)&.to_f
  end

  def validate_points_have_time(points)
    points.each_with_index do |pt, i|
      next if dig_key(pt, :time)

      raise ArgumentError, "Point at index #{i} is missing :time key required for splits"
    end
  end

  def point_time(point)
    t = dig_key(point, :time)
    t.respond_to?(:to_f) ? t.to_f : t
  end

  def interpolate_time(point_a, point_b, segment_km, distance_into_segment)
    return point_time(point_a) if segment_km.zero?

    t_a = point_time(point_a)
    t_b = point_time(point_b)
    t_a + ((t_b - t_a) * (distance_into_segment / segment_km))
  end

  # Formats a split pace, in either format, without ever raising.
  #
  # A GPS track can step backwards in time — a watch resyncing its clock, a
  # device paused and restarted, two segments merged out of order — which makes
  # a split elapsed time negative. That is bad data, not a caller error, and
  # track_splits has always reported it rather than blowing up; #sign_of keeps
  # it that way now that the compact format goes through #convert_to_clocktime,
  # which rejects negative durations.
  def seconds_to_pace(seconds, km, compact: false)
    pace_seconds = (seconds.to_f / km).round
    "#{sign_of(pace_seconds)}#{format_pace(pace_seconds.abs, compact: compact)}"
  end

  def sign_of(pace_seconds)
    pace_seconds.negative? ? '-' : ''
  end

  # The padded format keeps the historical MM:SS, where the minutes keep
  # counting past 60 (a 66-minute hiking split reads '66:33'); the compact
  # format defers to #convert_to_clocktime, which rolls those minutes into an
  # hour field ('1:06:33') exactly as it does everywhere else.
  def format_pace(pace_seconds, compact:)
    return convert_to_clocktime(pace_seconds, compact: true) if compact

    format('%<min>02d:%<sec>02d', min: pace_seconds / 60, sec: pace_seconds % 60)
  end

  # grade_factors, when given, holds one grade factor per segment (see
  # #segment_grade_factors) and turns on the :gap field; without it the splits
  # are exactly the ones #track_splits has always returned.
  def collect_splits(points, split_km, compact:, grade_factors: nil)
    state = { splits: [], start_time: point_time(points.first),
              split_start_time: point_time(points.first),
              accumulated_km: 0.0, split_number: 1, compact: compact,
              grade_factors: grade_factors, flat_equivalent_km: 0.0 }

    if grade_factors
      points.each_cons(2).with_index { |(a, b), index| process_segment(a, b, split_km, state, index) }
    else
      points.each_cons(2) { |a, b| process_segment(a, b, split_km, state) }
    end
    append_partial_split(points.last, split_km, state)
    state[:splits]
  end

  # index is only given, and the segment only tracked, when computing :gap —
  # track_splits keeps its original per-segment cost
  def process_segment(point_a, point_b, split_km, state, index = nil)
    segment_km = segment_distance_km(point_a, point_b)
    state[:accumulated_km] += segment_km
    state[:segment] = { assigned_km: 0.0, factor: state[:grade_factors].fetch(index) } if index

    while state[:accumulated_km] >= split_km * state[:split_number]
      record_split(point_a, point_b, segment_km, split_km, state)
    end

    accumulate_flat_equivalent(state, segment_km)
  end

  def record_split(point_a, point_b, segment_km, split_km, state)
    offset = (split_km * state[:split_number]) - (state[:accumulated_km] - segment_km)
    accumulate_flat_equivalent(state, offset)
    boundary_time = interpolate_time(point_a, point_b, segment_km, offset)
    state[:splits] << build_split_entry(boundary_time, split_km, state)
    state[:split_start_time] = boundary_time
    state[:split_number] += 1
    state[:flat_equivalent_km] = 0.0
  end

  def build_split_entry(boundary_time, split_km, state)
    split_elapsed = (boundary_time - state[:split_start_time]).round
    entry = {
      km: (split_km * state[:split_number]).round(2),
      elapsed: (boundary_time - state[:start_time]).round,
      pace: seconds_to_pace(split_elapsed, split_km, compact: state[:compact])
    }
    with_gap(entry, split_elapsed, state)
  end

  def append_partial_split(last_point, split_km, state)
    remaining_km = state[:accumulated_km] - (split_km * (state[:split_number] - 1))
    return unless remaining_km > 0.001

    last_time = point_time(last_point)
    split_elapsed = (last_time - state[:split_start_time]).round
    entry = {
      km: state[:accumulated_km].round(2),
      elapsed: (last_time - state[:start_time]).round,
      pace: seconds_to_pace(split_elapsed, remaining_km, compact: state[:compact])
    }
    state[:splits] << with_gap(entry, split_elapsed, state)
  end

  def segment_distance_km(point_a, point_b)
    haversine_distance(dig_key(point_a, :lat), dig_key(point_a, :lon),
                       dig_key(point_b, :lat), dig_key(point_b, :lon))
  end

  # Adds the flat-equivalent distance of the current segment up to
  # distance_into_segment, for the part not yet credited to an earlier split
  def accumulate_flat_equivalent(state, distance_into_segment)
    return unless state[:grade_factors]

    segment = state[:segment]

    state[:flat_equivalent_km] += (distance_into_segment - segment[:assigned_km]) * segment[:factor]
    segment[:assigned_km] = distance_into_segment
  end

  def with_gap(entry, split_elapsed, state)
    return entry unless state[:grade_factors]

    entry.merge(gap: seconds_to_pace(split_elapsed, state[:flat_equivalent_km], compact: state[:compact]))
  end

  # One grade factor per segment (consecutive point pair). Segments are grouped
  # into grade segments of at least GRADE_SEGMENT_MIN_KM, each with one grade
  # (net elevation change over horizontal distance); see
  # #track_grade_adjusted_splits for the rules.
  def segment_grade_factors(points)
    factors = Array.new(points.size - 1, 1.0)
    window = new_grade_window

    points.each_cons(2).with_index do |(a, b), index|
      window = extend_grade_window(window, factors, a, b, index)
    end
    close_grade_window(window, factors, final: true)
    factors
  end

  def new_grade_window(previous = nil)
    { indexes: [], km: 0.0, start_ele: nil, end_ele: nil, previous: previous }
  end

  def extend_grade_window(window, factors, point_a, point_b, index)
    ele_a = finite_ele(point_a)
    ele_b = finite_ele(point_b)
    if ele_a.nil? || ele_b.nil?
      close_grade_window(window, factors, final: true)
      return new_grade_window
    end

    add_to_grade_window(window, index, segment_distance_km(point_a, point_b), ele_a, ele_b)
    return window unless full_grade_window?(window)

    close_grade_window(window, factors, final: false)
    new_grade_window(window.except(:previous))
  end

  # Grade segments treat a NaN or infinite elevation like a missing one
  def finite_ele(point)
    ele = fetch_ele(point)
    ele if ele&.finite?
  end

  def add_to_grade_window(window, index, segment_km, ele_a, ele_b)
    window[:start_ele] ||= ele_a
    window[:end_ele] = ele_b
    window[:indexes] << index
    window[:km] += segment_km
  end

  # A full window gets its own grade. A short leftover — the end of the track
  # or of a stretch with elevation — is merged into the full window before it;
  # with no full window before it (a stretch shorter than a grade segment
  # between missing elevations, or a whole track that short) it stays flat
  # rather than being graded over a few noisy metres.
  def close_grade_window(window, factors, final:)
    return if window[:indexes].empty?

    unless full_grade_window?(window)
      return unless final && window[:previous]

      window = merge_grade_windows(window[:previous], window)
    end
    factor = grade_adjustment_factor(window_grade(window))
    window[:indexes].each { |index| factors[index] = factor }
  end

  def full_grade_window?(window)
    window[:km] >= GRADE_SEGMENT_MIN_KM - GRADE_SEGMENT_TOLERANCE_KM
  end

  def merge_grade_windows(previous, window)
    { indexes: previous[:indexes] + window[:indexes], km: previous[:km] + window[:km],
      start_ele: previous[:start_ele], end_ele: window[:end_ele] }
  end

  def window_grade(window)
    return 0.0 unless window[:km].positive?

    (window[:end_ele] - window[:start_ele]) / (window[:km] * 1000.0)
  end
end
