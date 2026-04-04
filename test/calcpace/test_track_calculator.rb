# frozen_string_literal: true

require_relative '../test_helper'

# Tests for TrackCalculator module — GPS distance, elevation and splits
class TestTrackCalculator < CalcpaceTest
  # ---------------------------------------------------------------------------
  # haversine_distance
  # ---------------------------------------------------------------------------

  def test_haversine_distance_known_pair
    # São Paulo city center to ~89 m east — verified against online calculators
    result = @calc.haversine_distance(-23.5505, -46.6333, -23.5510, -46.6340)
    assert_in_delta 0.089, result, 0.005
  end

  def test_haversine_distance_same_point_is_zero
    result = @calc.haversine_distance(-23.5505, -46.6333, -23.5505, -46.6333)
    assert_in_delta 0.0, result, 0.0001
  end

  def test_haversine_distance_known_longer_segment
    # Roughly 1 km north along a meridian (0.009 degrees lat ≈ 1 km)
    result = @calc.haversine_distance(0.0, 0.0, 0.009, 0.0)
    assert_in_delta 1.0, result, 0.01
  end

  def test_haversine_distance_invalid_latitude_raises
    assert_raises(ArgumentError) { @calc.haversine_distance(91, 0, 0, 0) }
    assert_raises(ArgumentError) { @calc.haversine_distance(-91, 0, 0, 0) }
  end

  def test_haversine_distance_invalid_longitude_raises
    assert_raises(ArgumentError) { @calc.haversine_distance(0, 181, 0, 0) }
    assert_raises(ArgumentError) { @calc.haversine_distance(0, -181, 0, 0) }
  end

  # ---------------------------------------------------------------------------
  # track_distance
  # ---------------------------------------------------------------------------

  def test_track_distance_with_three_points
    points = [
      { lat: -23.5505, lon: -46.6333 },
      { lat: -23.5510, lon: -46.6340 },
      { lat: -23.5520, lon: -46.6350 }
    ]
    result = @calc.track_distance(points)
    assert_kind_of Float, result
    assert result > 0.1
    assert result < 0.5
  end

  def test_track_distance_empty_array_returns_zero
    assert_equal 0.0, @calc.track_distance([])
  end

  def test_track_distance_single_point_returns_zero
    assert_equal 0.0, @calc.track_distance([{ lat: -23.5505, lon: -46.6333 }])
  end

  def test_track_distance_nil_returns_zero
    assert_equal 0.0, @calc.track_distance(nil)
  end

  def test_track_distance_returns_float_rounded_to_2_decimals
    points = [
      { lat: 0.0, lon: 0.0 },
      { lat: 0.009, lon: 0.0 },
      { lat: 0.018, lon: 0.0 }
    ]
    result = @calc.track_distance(points)
    assert_equal result.round(2), result
  end

  def test_track_distance_accepts_string_keys
    points = [
      { 'lat' => -23.5505, 'lon' => -46.6333 },
      { 'lat' => -23.5510, 'lon' => -46.6340 }
    ]
    result = @calc.track_distance(points)
    assert result.positive?
  end

  # ---------------------------------------------------------------------------
  # elevation_gain
  # ---------------------------------------------------------------------------

  def test_elevation_gain_uphill
    points = [
      { lat: 0, lon: 0, ele: 100.0 },
      { lat: 0, lon: 0, ele: 105.0 },
      { lat: 0, lon: 0, ele: 110.0 }
    ]
    result = @calc.elevation_gain(points)
    assert_equal 10.0, result[:gain]
    assert_equal 0.0, result[:loss]
  end

  def test_elevation_gain_downhill
    points = [
      { lat: 0, lon: 0, ele: 110.0 },
      { lat: 0, lon: 0, ele: 105.0 },
      { lat: 0, lon: 0, ele: 100.0 }
    ]
    result = @calc.elevation_gain(points)
    assert_equal 0.0, result[:gain]
    assert_equal 10.0, result[:loss]
  end

  def test_elevation_gain_mixed
    points = [
      { lat: 0, lon: 0, ele: 100.0 },
      { lat: 0, lon: 0, ele: 105.0 },
      { lat: 0, lon: 0, ele: 102.0 }
    ]
    result = @calc.elevation_gain(points)
    assert_equal 5.0, result[:gain]
    assert_equal 3.0, result[:loss]
  end

  def test_elevation_gain_flat
    points = [
      { lat: 0, lon: 0, ele: 100.0 },
      { lat: 0, lon: 0, ele: 100.0 },
      { lat: 0, lon: 0, ele: 100.0 }
    ]
    result = @calc.elevation_gain(points)
    assert_equal 0.0, result[:gain]
    assert_equal 0.0, result[:loss]
  end

  def test_elevation_gain_points_without_ele_returns_zero
    points = [
      { lat: -23.5505, lon: -46.6333 },
      { lat: -23.5510, lon: -46.6340 }
    ]
    result = @calc.elevation_gain(points)
    assert_equal({ gain: 0.0, loss: 0.0 }, result)
  end

  def test_elevation_gain_empty_array_returns_zero
    result = @calc.elevation_gain([])
    assert_equal({ gain: 0.0, loss: 0.0 }, result)
  end

  def test_elevation_gain_accepts_string_keys
    points = [
      { 'lat' => 0, 'lon' => 0, 'ele' => 100.0 },
      { 'lat' => 0, 'lon' => 0, 'ele' => 103.0 }
    ]
    result = @calc.elevation_gain(points)
    assert_equal 3.0, result[:gain]
  end

  # ---------------------------------------------------------------------------
  # track_splits
  # ---------------------------------------------------------------------------

  # Build a straight-line track with evenly-spaced points going north.
  # step_lat ≈ 0.001 degrees ≈ 111 m per step.
  # 10 steps × 111 m ≈ 1.11 km → gives ~1 full split at 1 km.
  def build_track(num_points:, step_lat: 0.001, pace_sec_per_km: 300)
    start_time = Time.new(2026, 1, 1, 7, 0, 0)
    (0...num_points).map do |i|
      lat = i * step_lat
      # time at each point: proportional to distance covered
      t = start_time + (i * step_lat * 111.0 * pace_sec_per_km)
      { lat: lat, lon: 0.0, ele: 100.0, time: t }
    end
  end

  def test_track_splits_returns_array
    points = build_track(num_points: 20)
    result = @calc.track_splits(points, 1.0)
    assert_kind_of Array, result
  end

  def test_track_splits_split_has_expected_keys
    points = build_track(num_points: 20)
    result = @calc.track_splits(points, 1.0)
    assert result.any?
    split = result.first
    assert split.key?(:km)
    assert split.key?(:elapsed)
    assert split.key?(:pace)
  end

  def test_track_splits_pace_format
    points = build_track(num_points: 20)
    result = @calc.track_splits(points, 1.0)
    result.each do |split|
      assert_match(/\A\d{2}:\d{2}\z/, split[:pace], "Pace #{split[:pace]} should be MM:SS")
    end
  end

  def test_track_splits_5km_track_yields_at_least_4_splits
    # ~45 points × 0.001° ≈ 5 km
    points = build_track(num_points: 50)
    result = @calc.track_splits(points, 1.0)
    assert result.size >= 4
  end

  def test_track_splits_empty_array_returns_empty
    assert_equal [], @calc.track_splits([], 1.0)
  end

  def test_track_splits_single_point_returns_empty
    points = build_track(num_points: 1)
    assert_equal [], @calc.track_splits(points, 1.0)
  end

  def test_track_splits_invalid_split_km_raises
    points = build_track(num_points: 5)
    assert_raises(ArgumentError) { @calc.track_splits(points, 0) }
    assert_raises(ArgumentError) { @calc.track_splits(points, -1) }
  end

  def test_track_splits_missing_time_raises
    points = [
      { lat: 0.0, lon: 0.0 },
      { lat: 0.001, lon: 0.0 }
    ]
    assert_raises(ArgumentError) { @calc.track_splits(points, 1.0) }
  end

  def test_track_splits_mile_split
    points = build_track(num_points: 30)
    # 1 mile ≈ 1.60934 km
    result = @calc.track_splits(points, 1.60934)
    assert_kind_of Array, result
  end

  def test_track_splits_km_values_increase
    points = build_track(num_points: 50)
    result = @calc.track_splits(points, 1.0)
    kms = result.map { |s| s[:km] }
    assert_equal kms, kms.sort
  end

  def test_track_splits_elapsed_values_increase
    points = build_track(num_points: 50)
    result = @calc.track_splits(points, 1.0)
    elapsed = result.map { |s| s[:elapsed] }
    assert_equal elapsed, elapsed.sort
  end
end
