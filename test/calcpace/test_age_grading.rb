# frozen_string_literal: true

require_relative '../test_helper'

# Tests for AgeGrading module
class TestAgeGrading < CalcpaceTest
  def test_age_grade_returns_expected_shape
    result = @calc.age_grade(10.0, '00:45:00', age: 55, sex: :male)

    assert_kind_of Hash, result
    assert_equal 'WMA_2023_ONE_YEAR_FACTORS_V1', result[:table_version]
    assert_includes result.keys, :age_grade_percent
    assert_includes result.keys, :category
    assert_includes result.keys, :age_graded_time_seconds
    assert_includes result.keys, :age_graded_time_clock
    assert_includes result.keys, :open_standard_seconds
    assert_includes result.keys, :open_standard_clock
    assert_includes result.keys, :factor
  end

  def test_age_grade_percent_increases_with_faster_time
    slower = @calc.age_grade_percent(10.0, '00:50:00', age: 55, sex: :male)
    faster = @calc.age_grade_percent(10.0, '00:40:00', age: 55, sex: :male)

    assert faster > slower
  end

  def test_age_graded_time_is_faster_for_masters_age
    result = @calc.age_grade(10.0, '00:45:00', age: 60, sex: :female)
    raw_seconds = @calc.convert_to_seconds('00:45:00')

    assert result[:age_graded_time_seconds] < raw_seconds
  end

  def test_accepts_time_in_seconds
    result = @calc.age_grade(5.0, 1500, age: 50, sex: 'female')
    assert_kind_of Float, result[:age_grade_percent]
    assert result[:age_grade_percent].positive?
  end

  def test_accepts_race_symbol_keys
    result = @calc.age_grade(:marathon, '03:30:00', age: 50, sex: :male)
    assert_kind_of Hash, result
    assert result[:age_grade_percent].positive?
  end

  def test_accepts_race_string_keys
    result = @calc.age_grade('half_marathon', '01:45:00', age: 45, sex: :female)
    assert_kind_of Hash, result
    assert result[:age_grade_percent].positive?
  end

  def test_age_factored_time_rounds_up_to_hundredth
    result = @calc.age_grade(10.0, 2711, age: 55, sex: :male)
    scaled = (result[:age_graded_time_seconds] * 100).to_i
    assert_equal result[:age_graded_time_seconds], (scaled / 100.0)
  end

  def test_interpolates_factor_for_in_between_age
    result_fifty_five = @calc.age_grade(10.0, '00:45:00', age: 55, sex: :male)
    result_fifty_seven = @calc.age_grade(10.0, '00:45:00', age: 57, sex: :male)
    result_sixty = @calc.age_grade(10.0, '00:45:00', age: 60, sex: :male)

    assert result_fifty_seven[:factor] < result_fifty_five[:factor]
    assert result_fifty_seven[:factor] > result_sixty[:factor]
  end

  def test_label_classification
    assert_equal 'Approximate World Record Level', @calc.age_grade_label(100.0)
    assert_equal 'World Class', @calc.age_grade_label(90.0)
    assert_equal 'National Class', @calc.age_grade_label(80.0)
    assert_equal 'Regional Class', @calc.age_grade_label(70.0)
    assert_equal 'Local Class', @calc.age_grade_label(60.0)
    assert_equal 'Intermediate', @calc.age_grade_label(59.9)
    assert_equal 'Intermediate', @calc.age_grade_label(50.0)
    assert_equal 'Recreational', @calc.age_grade_label(49.9)
    assert_equal 'Recreational', @calc.age_grade_label(40.0)
    assert_equal 'Active Beginner', @calc.age_grade_label(39.9)
    assert_equal 'Active Beginner', @calc.age_grade_label(0.0)
  end

  def test_age_grade_label_rounding_moves_the_boundary
    # 59.9886% is "Intermediate" unrounded, but rounds to 60.0, which is
    # "Local Class" - the boundary is decided by the rounded value.
    assert_equal 'Intermediate', @calc.age_grade_label(59.9886)
    assert_equal 'Local Class', @calc.age_grade_label(59.9886.round(1))

    result = @calc.age_grade(10.0, 2750, age: 40, sex: :male)
    assert_equal 60.0, result[:age_grade_percent]
    assert_equal 'Local Class', result[:category]
  end

  def test_age_grade_label_nan_raises_but_infinity_is_top_band
    assert_raises(ArgumentError) { @calc.age_grade_label(Float::NAN) }
    assert_equal 'Approximate World Record Level', @calc.age_grade_label(Float::INFINITY)
    assert_raises(ArgumentError) { @calc.age_grade_label(-Float::INFINITY) }
  end

  def test_age_grade_labels_are_sorted_descending_and_end_at_zero
    mins = AgeGrading::AGE_GRADE_LABELS.map { |entry| entry[:min] }

    assert mins.each_cons(2).all? { |higher, lower| higher > lower }, 'expected mins to be strictly descending'
    assert_equal 0.0, mins.last
  end

  def test_raises_for_invalid_distance
    assert_raises(ArgumentError) do
      @calc.age_grade(7.0, '00:35:00', age: 45, sex: :male)
    end
  end

  def test_raises_for_invalid_age
    assert_raises(ArgumentError) do
      @calc.age_grade(10.0, '00:45:00', age: 15, sex: :male)
    end
  end

  def test_raises_for_invalid_sex
    assert_raises(ArgumentError) do
      @calc.age_grade(10.0, '00:45:00', age: 45, sex: :other)
    end
  end

  def test_raises_for_invalid_time
    assert_raises(Calcpace::InvalidTimeFormatError) do
      @calc.age_grade(10.0, 'fast', age: 45, sex: :male)
    end
  end

  def test_age_grade_percent_accepts_distances_as_runners_write_them_in_miles
    # Real-world mile inputs, not 6-decimal conversions: 3.1mi ≈ 5k, 6.2mi ≈ 10k,
    # 13.1mi ≈ half marathon, 26.2mi ≈ marathon
    { 3.1 => 5.0, 6.2 => 10.0, 13.1 => 21.0975, 26.2 => 42.195 }.each do |miles, km|
      expected = @calc.age_grade_percent(km, '01:30:00', age: 40, sex: :male)
      actual = @calc.age_grade_percent(miles, '01:30:00', age: 40, sex: :male, distance_unit: :mi)

      assert_equal expected, actual, "#{miles} mi should resolve to the #{km} km standard"
    end
  end

  def test_age_grade_percent_accepts_exact_mile_conversions
    km = @calc.age_grade_percent(21.0975, '01:30:00', age: 40, sex: :male)
    mi = @calc.age_grade_percent(13.109455, '01:30:00', age: 40, sex: :male, distance_unit: :mi)

    assert_equal km, mi
  end

  def test_age_grade_still_rejects_distances_outside_tolerance
    error = assert_raises(ArgumentError) do
      @calc.age_grade(7.5, '00:35:00', age: 45, sex: :male)
    end

    assert_match(/7\.5/, error.message)
  end

  def test_age_grade_error_message_reports_the_input_in_its_own_unit
    error = assert_raises(ArgumentError) do
      @calc.age_grade(9.0, '01:00:00', age: 40, sex: :male, distance_unit: :mi)
    end

    assert_match(/9\.0/, error.message)
    assert_match(/mi/, error.message)
    refute_match(/9\.0\s*km/, error.message)
  end

  def test_age_grade_rejects_distance_unit_with_race_key
    # A race key already carries its own distance, so a distance_unit alongside it
    # is always a caller mistake — say so instead of silently ignoring the keyword
    error = assert_raises(ArgumentError) do
      @calc.age_grade_percent('10k', '00:45:00', age: 40, sex: :male, distance_unit: :mi)
    end

    assert_match(/race name/i, error.message)
  end

  def test_age_grade_tolerates_whitespace_and_case_in_race_keys
    padded = @calc.age_grade_percent(' 10K ', '00:45:00', age: 40, sex: :male)

    assert_equal @calc.age_grade_percent('10k', '00:45:00', age: 40, sex: :male), padded
  end

  def test_age_grade_rejects_unknown_distance_unit
    assert_raises(Calcpace::UnsupportedUnitError) do
      @calc.age_grade(21.0975, '01:30:00', age: 40, sex: :male, distance_unit: :furlong)
    end
  end

  # --- tolerance widened to 2% in v1.15.0, to match the site's race_key ---

  def test_age_grade_accepts_a_distance_within_two_percent_of_the_standard
    # A GPS 5K rarely reads exactly 5.000 km: 5.0374 is a real Strava reading,
    # and 2% is the same window the site uses to call a run "a 5K"
    assert_equal @calc.age_grade_percent(5.0, '00:25:00', age: 40, sex: :male),
                 @calc.age_grade_percent(5.0374, '00:25:00', age: 40, sex: :male)
  end

  def test_age_grade_tolerance_borders_on_both_sides
    [4.91, 5.09, 9.81, 10.19].each do |distance|
      assert @calc.age_grade_percent(distance, '00:45:00', age: 40, sex: :male),
             "#{distance} km is inside the 2% window and should be graded"
    end

    [4.89, 5.11, 9.79, 10.21].each do |distance|
      assert_raises(ArgumentError, "#{distance} km is outside the 2% window") do
        @calc.age_grade(distance, '00:45:00', age: 40, sex: :male)
      end
    end
  end

  def test_age_grade_still_rejects_a_non_standard_distance
    # 7.79 km is 22% off a 10K. The WMA publishes a factor per specific
    # distance, so there is no honest number to return here: interpolating one
    # would invent a value with the look of an official standard
    error = assert_raises(ArgumentError) do
      @calc.age_grade(7.79, '00:26:59', age: 36, sex: :male)
    end

    assert_match(/Unsupported distance/, error.message)
  end
end
