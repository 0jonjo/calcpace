# frozen_string_literal: true

require_relative '../test_helper'

# Tests for grade-adjusted pace (Minetti et al., 2002) and its GPS-track splits
class TestGradeAdjustedPace < CalcpaceTest
  # Minetti et al. (2002) running polynomial, evaluated independently of the
  # library so a typo in a coefficient cannot pass by agreeing with itself
  def minetti(grade)
    (155.4 * (grade**5)) - (30.4 * (grade**4)) - (43.3 * (grade**3)) +
      (46.3 * (grade**2)) + (19.5 * grade) + 3.6
  end

  # ---------------------------------------------------------------------------
  # grade_adjustment_factor
  # ---------------------------------------------------------------------------

  def test_factor_is_one_on_the_flat
    assert_in_delta 1.0, @calc.grade_adjustment_factor(0), 1e-12
  end

  def test_factor_follows_the_minetti_polynomial
    [-0.3, -0.1, -0.05, 0.05, 0.1, 0.3].each do |grade|
      assert_in_delta minetti(grade) / 3.6, @calc.grade_adjustment_factor(grade), 1e-12
    end
  end

  def test_factor_known_values
    assert_in_delta 1.658, @calc.grade_adjustment_factor(0.10), 0.001
    assert_in_delta 0.598, @calc.grade_adjustment_factor(-0.10), 0.001
  end

  def test_factor_is_cheapest_around_minus_twenty_percent
    assert_operator @calc.grade_adjustment_factor(-0.20), :<, @calc.grade_adjustment_factor(-0.10)
    assert_operator @calc.grade_adjustment_factor(-0.20), :<, @calc.grade_adjustment_factor(-0.30)
  end

  def test_factor_clamps_to_the_measured_range
    assert_equal @calc.grade_adjustment_factor(0.45), @calc.grade_adjustment_factor(0.6)
    assert_equal @calc.grade_adjustment_factor(-0.45), @calc.grade_adjustment_factor(-1)
  end

  def test_factor_rejects_non_numeric_or_non_finite_grades
    [nil, '0.05', Float::NAN, Float::INFINITY, -Float::INFINITY].each do |grade|
      assert_raises(ArgumentError) { @calc.grade_adjustment_factor(grade) }
    end
  end

  # ---------------------------------------------------------------------------
  # grade_adjusted_pace / grade_adjusted_pace_clock
  # ---------------------------------------------------------------------------

  def test_uphill_pace_is_faster_on_the_flat
    assert_in_delta 360 / (minetti(0.10) / 3.6), @calc.grade_adjusted_pace(360, 0.10), 1e-9
  end

  def test_downhill_pace_is_slower_on_the_flat
    assert_operator @calc.grade_adjusted_pace(300, -0.05), :>, 300
  end

  def test_flat_pace_is_unchanged
    assert_in_delta 300.0, @calc.grade_adjusted_pace(300, 0), 1e-12
  end

  def test_accepts_a_clock_pace
    assert_equal @calc.grade_adjusted_pace(360, 0.05), @calc.grade_adjusted_pace('06:00', 0.05)
  end

  def test_returns_a_float
    assert_kind_of Float, @calc.grade_adjusted_pace(300, 0)
  end

  def test_unit_does_not_change_the_math
    assert_equal @calc.grade_adjusted_pace(480, 0.05), @calc.grade_adjusted_pace(480, 0.05, unit: :mi)
  end

  def test_rejects_unknown_unit
    assert_raises(Calcpace::UnsupportedUnitError) { @calc.grade_adjusted_pace(300, 0.05, unit: :furlong) }
  end

  def test_rejects_non_positive_pace
    assert_raises(Calcpace::NonPositiveInputError) { @calc.grade_adjusted_pace(0, 0.05) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.grade_adjusted_pace(-300, 0.05) }
  end

  def test_rejects_malformed_clock_pace
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.grade_adjusted_pace('06:xx', 0.05) }
  end

  def test_rejects_invalid_grade
    assert_raises(ArgumentError) { @calc.grade_adjusted_pace(300, nil) }
  end

  def test_clock_formats
    assert_equal '00:03:37', @calc.grade_adjusted_pace_clock('06:00', 0.10)
    assert_equal '3:37', @calc.grade_adjusted_pace_clock('06:00', 0.10, compact: true)
  end

  # ---------------------------------------------------------------------------
  # track_grade_adjusted_splits
  # ---------------------------------------------------------------------------

  # Degrees of latitude per kilometre on the gem's spherical Earth
  KM_PER_DEGREE = TrackCalculator::EARTH_RADIUS_KM * Math::PI / 180.0

  # A straight track going north, one point every step_m metres, run at a
  # steady pace. ele: is a lambda of the horizontal distance in metres, or nil
  # to leave elevation out entirely.
  def build_track(distance_m:, step_m: 10, pace_sec_per_km: 300, ele: ->(_m) { 100.0 })
    start = Time.new(2026, 1, 1, 7, 0, 0)
    (0..(distance_m / step_m)).map do |i|
      metres = i * step_m
      point = { lat: metres / 1000.0 / KM_PER_DEGREE, lon: 0.0, time: start + (metres / 1000.0 * pace_sec_per_km) }
      point[:ele] = ele.call(metres) if ele
      point
    end
  end

  def pace_seconds(clock)
    sign = clock.start_with?('-') ? -1 : 1
    minutes, seconds = clock.delete_prefix('-').split(':').map(&:to_i)
    sign * ((minutes * 60) + seconds)
  end

  def test_keeps_track_splits_fields_identical
    points = build_track(distance_m: 2500, ele: ->(m) { 100 + (0.05 * m) })

    gap_splits = @calc.track_grade_adjusted_splits(points, 1.0)

    assert_equal(@calc.track_splits(points, 1.0),
                 gap_splits.map { |split| split.except(:gap) })
  end

  def test_track_splits_output_is_unchanged_by_elevation
    flat = build_track(distance_m: 2500)
    hilly = build_track(distance_m: 2500, ele: ->(m) { 100 + (0.05 * m) })

    assert_equal @calc.track_splits(flat, 1.0), @calc.track_splits(hilly, 1.0)
    assert_equal %i[km elapsed pace], @calc.track_splits(hilly, 1.0).first.keys
  end

  def test_adds_a_gap_field_to_every_split
    points = build_track(distance_m: 2500)
    result = @calc.track_grade_adjusted_splits(points, 1.0)

    assert_equal 3, result.size
    result.each { |split| assert_equal %i[km elapsed pace gap], split.keys }
  end

  def test_flat_track_gap_equals_pace
    points = build_track(distance_m: 2500)

    @calc.track_grade_adjusted_splits(points, 1.0).each do |split|
      assert_equal split[:pace], split[:gap]
    end
  end

  def test_track_without_elevation_is_treated_as_flat
    points = build_track(distance_m: 2500, ele: nil)

    @calc.track_grade_adjusted_splits(points, 1.0).each do |split|
      assert_equal split[:pace], split[:gap]
    end
  end

  def test_steady_climb_gap_matches_the_single_grade_formula
    points = build_track(distance_m: 3000, ele: ->(m) { 100 + (0.05 * m) })
    expected = @calc.grade_adjusted_pace(300, 0.05)

    @calc.track_grade_adjusted_splits(points, 1.0).each do |split|
      assert_equal '05:00', split[:pace]
      assert_in_delta expected, pace_seconds(split[:gap]), 1
    end
  end

  def test_steady_descent_gap_is_slower_than_pace
    points = build_track(distance_m: 2000, ele: ->(m) { 500 - (0.05 * m) })

    @calc.track_grade_adjusted_splits(points, 1.0).each do |split|
      assert_operator pace_seconds(split[:gap]), :>, pace_seconds(split[:pace])
    end
  end

  # One-metre GPS points with up to ±2 m of elevation jitter on flat ground.
  # Read point to point that is a grade of up to ±400% on every segment —
  # clamped to ±45%, and the factor's curvature turns that symmetric noise into
  # a fake climb worth a GAP around 1:30/km. Over 100 m grade segments what is
  # left is the noise at the split's two ends (up to 4 m of net "climb" over
  # 1 km, about 2%) and a little curvature: a few seconds
  def test_elevation_noise_on_short_segments_does_not_create_fake_grades
    points = build_track(distance_m: 2000, step_m: 1, ele: ->(m) { 100 + (2.0 * Math.sin(m * 1.7)) })

    @calc.track_grade_adjusted_splits(points, 1.0).each do |split|
      assert_in_delta pace_seconds(split[:pace]), pace_seconds(split[:gap]), 10
    end
  end

  def test_climb_then_descent_lands_in_the_right_splits
    points = build_track(distance_m: 2000, ele: ->(m) { m <= 1000 ? 100 + (0.08 * m) : 180 - (0.08 * (m - 1000)) })
    first, second = @calc.track_grade_adjusted_splits(points, 1.0)

    assert_in_delta @calc.grade_adjusted_pace(300, 0.08), pace_seconds(first[:gap]), 1
    assert_in_delta @calc.grade_adjusted_pace(300, -0.08), pace_seconds(second[:gap]), 1
  end

  def test_points_missing_elevation_are_flat_segments
    # Elevation dropped for the whole second kilometre (a GPS fix without
    # altitude): that kilometre counts as flat, the first keeps its climb
    points = build_track(distance_m: 2000, ele: ->(m) { 100 + (0.05 * m) })
    points.each { |point| point.delete(:ele) if point[:lat] * KM_PER_DEGREE > 1.0 }
    first, second = @calc.track_grade_adjusted_splits(points, 1.0)

    assert_operator pace_seconds(first[:gap]), :<, pace_seconds(first[:pace])
    assert_equal second[:pace], second[:gap]
  end

  def test_string_keys_are_accepted
    points = build_track(distance_m: 1000, ele: ->(m) { 100 + (0.05 * m) })
             .map { |point| point.transform_keys(&:to_s) }

    split = @calc.track_grade_adjusted_splits(points, 1.0).first
    assert_operator pace_seconds(split[:gap]), :<, pace_seconds(split[:pace])
  end

  def test_compact_gap_format
    points = build_track(distance_m: 1000, ele: ->(m) { 100 + (0.05 * m) })
    padded = @calc.track_grade_adjusted_splits(points, 1.0).first
    compact = @calc.track_grade_adjusted_splits(points, 1.0, compact: true).first

    assert_equal padded[:gap].delete_prefix('0'), compact[:gap]
    assert_equal '5:00', compact[:pace]
  end

  def test_partial_split_gets_a_gap
    points = build_track(distance_m: 1500, ele: ->(m) { 100 + (0.05 * m) })
    partial = @calc.track_grade_adjusted_splits(points, 1.0).last

    assert_equal 1.5, partial[:km]
    assert_in_delta @calc.grade_adjusted_pace(300, 0.05), pace_seconds(partial[:gap]), 1
  end

  def test_empty_or_single_point_tracks_return_empty
    assert_equal [], @calc.track_grade_adjusted_splits([], 1.0)
    assert_equal [], @calc.track_grade_adjusted_splits(nil, 1.0)
    assert_equal [], @calc.track_grade_adjusted_splits(build_track(distance_m: 0), 1.0)
  end

  def test_validates_like_track_splits
    points = build_track(distance_m: 100)
    assert_raises(ArgumentError) { @calc.track_grade_adjusted_splits(points, 0) }
    assert_raises(ArgumentError) { @calc.track_grade_adjusted_splits([{ lat: 0, lon: 0 }, { lat: 0.001, lon: 0 }], 1.0) }
  end
end
