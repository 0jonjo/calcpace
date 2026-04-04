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
#   calc.track_distance(points) #=> 0.17 (km)
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
  #   #=> 0.089 (km)
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
  #   track_distance(points) #=> 0.17
  def track_distance(points)
    return 0.0 if points.nil? || points.size < 2

    total = points.each_cons(2).sum do |a, b|
      haversine_distance(fetch_coord(a, :lat), fetch_coord(a, :lon),
                         fetch_coord(b, :lat), fetch_coord(b, :lon))
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
  # @param points [Array<Hash>] array of points with :lat, :lon, and :time keys.
  #   :time must respond to #to_f (Unix timestamp) or be a Time object.
  # @param split_km [Numeric] split interval in kilometers (default: 1.0)
  # @return [Array<Hash>] array of split hashes, each with:
  #   - :km [Float] cumulative distance at split end
  #   - :elapsed [Integer] elapsed seconds from start of track to end of split
  #   - :pace [String] pace for this split in MM:SS format
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
  def track_splits(points, split_km = 1.0)
    raise ArgumentError, 'split_km must be positive' unless split_km.is_a?(Numeric) && split_km.positive?
    return [] if points.nil? || points.size < 2

    validate_points_have_time(points)
    collect_splits(points, split_km)
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

  def fetch_coord(point, key)
    point[key] || point[key.to_s]
  end

  def fetch_ele(point)
    val = point[:ele] || point['ele']
    val&.to_f
  end

  def validate_points_have_time(points)
    points.each_with_index do |pt, i|
      next if pt[:time] || pt['time']

      raise ArgumentError, "Point at index #{i} is missing :time key required for splits"
    end
  end

  def point_time(point)
    t = point[:time] || point['time']
    t.respond_to?(:to_f) ? t.to_f : t
  end

  def interpolate_time(point_a, point_b, segment_km, distance_into_segment)
    return point_time(point_a) if segment_km.zero?

    t_a = point_time(point_a)
    t_b = point_time(point_b)
    t_a + ((t_b - t_a) * (distance_into_segment / segment_km))
  end

  def seconds_to_pace(seconds, km)
    return '00:00' if km.zero?

    pace_seconds = (seconds.to_f / km).round
    format('%<min>02d:%<sec>02d', min: pace_seconds / 60, sec: pace_seconds % 60)
  end

  def collect_splits(points, split_km)
    state = { splits: [], start_time: point_time(points.first),
              split_start_time: point_time(points.first),
              accumulated_km: 0.0, split_number: 1 }

    points.each_cons(2) { |a, b| process_segment(a, b, split_km, state) }
    append_partial_split(points.last, split_km, state)
    state[:splits]
  end

  def process_segment(point_a, point_b, split_km, state)
    segment_km = haversine_distance(fetch_coord(point_a, :lat), fetch_coord(point_a, :lon),
                                    fetch_coord(point_b, :lat), fetch_coord(point_b, :lon))
    state[:accumulated_km] += segment_km

    while state[:accumulated_km] >= split_km * state[:split_number]
      record_split(point_a, point_b, segment_km, split_km, state)
    end
  end

  def record_split(point_a, point_b, segment_km, split_km, state)
    offset = (split_km * state[:split_number]) - (state[:accumulated_km] - segment_km)
    boundary_time = interpolate_time(point_a, point_b, segment_km, offset)
    state[:splits] << build_split_entry(boundary_time, split_km, state)
    state[:split_start_time] = boundary_time
    state[:split_number] += 1
  end

  def build_split_entry(boundary_time, split_km, state)
    split_elapsed = (boundary_time - state[:split_start_time]).round
    {
      km: (split_km * state[:split_number]).round(2),
      elapsed: (boundary_time - state[:start_time]).round,
      pace: seconds_to_pace(split_elapsed, split_km)
    }
  end

  def append_partial_split(last_point, split_km, state)
    remaining_km = state[:accumulated_km] - (split_km * (state[:split_number] - 1))
    return unless remaining_km > 0.001

    last_time = point_time(last_point)
    state[:splits] << {
      km: state[:accumulated_km].round(2),
      elapsed: (last_time - state[:start_time]).round,
      pace: seconds_to_pace((last_time - state[:split_start_time]).round, remaining_km)
    }
  end
end
