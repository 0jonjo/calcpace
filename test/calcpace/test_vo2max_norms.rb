# frozen_string_literal: true

require_relative '../test_helper'

# Tests for VO2max percentiles and labels by age and sex (FRIEND 2015, Table 3)
class TestVo2maxNorms < CalcpaceTest
  # --- vo2max_label without age/sex: unchanged ---

  def test_label_without_age_and_sex_keeps_the_fixed_thresholds
    { 72.0 => 'Elite', 70 => 'Elite', 65.0 => 'Excellent', 51.9 => 'Very Good',
      45 => 'Good', 35.0 => 'Fair', 29.9 => 'Beginner' }.each do |value, label|
      assert_equal label, @calc.vo2max_label(value)
      assert_equal label, @calc.vo2max_label(value, age: nil, sex: nil)
    end
  end

  def test_label_needs_age_and_sex_together
    assert_raises(ArgumentError) { @calc.vo2max_label(45, age: 30) }
    assert_raises(ArgumentError) { @calc.vo2max_label(45, sex: :male) }
  end

  def test_label_with_norms_still_rejects_non_positive_values
    assert_raises(Calcpace::NonPositiveInputError) { @calc.vo2max_label(0, age: 30, sex: :male) }
  end

  # --- vo2max_label with age/sex ---

  def test_same_value_reads_differently_by_age_and_sex
    assert_equal 'Fair', @calc.vo2max_label(45, age: 25, sex: :male)
    assert_equal 'Elite', @calc.vo2max_label(45, age: 60, sex: :male)
    assert_equal 'Very Good', @calc.vo2max_label(45, age: 25, sex: :female)
    assert_equal 'Elite', @calc.vo2max_label(45, age: 60, sex: :female)
  end

  # Men 40–49 from FRIEND: 25th 31.9, 50th 37.8, 75th 45.0, 90th 52.1, 95th 55.6
  def test_label_cuts_sit_on_the_published_percentiles
    {
      55.6 => 'Elite', 55.59 => 'Excellent',
      52.1 => 'Excellent', 52.09 => 'Very Good',
      45.0 => 'Very Good', 44.99 => 'Good',
      37.8 => 'Good', 37.79 => 'Fair',
      31.9 => 'Fair', 31.89 => 'Beginner',
      10.0 => 'Beginner'
    }.each do |value, label|
      assert_equal label, @calc.vo2max_label(value, age: 45, sex: :male), "VO2max #{value}"
    end
  end

  def test_label_uses_the_same_six_labels
    labels = (10..90).map { |value| @calc.vo2max_label(value, age: 35, sex: :female) }.uniq
    assert_empty labels - Vo2maxEstimator::VO2MAX_LABELS.map { |entry| entry[:label] }
  end

  # --- vo2max_percentile ---

  def test_percentile_on_a_published_point
    assert_equal 50.0, @calc.vo2max_percentile(48.0, age: 25, sex: :male)
    assert_equal 75.0, @calc.vo2max_percentile(44.7, age: 25, sex: :female)
    assert_equal 10.0, @calc.vo2max_percentile(14.6, age: 65, sex: :female)
  end

  def test_percentile_interpolates_linearly_between_published_points
    # Men 20–29: 25th 40.1, 50th 48.0
    assert_in_delta 40.5, @calc.vo2max_percentile(45, age: 25, sex: :male), 0.05
    assert_equal 37.5, @calc.vo2max_percentile(44.05, age: 25, sex: :male)
  end

  def test_percentile_is_bounded_to_the_table
    assert_equal 95.0, @calc.vo2max_percentile(80, age: 25, sex: :male)
    assert_equal 95.0, @calc.vo2max_percentile(66.3, age: 25, sex: :male)
    assert_equal 5.0, @calc.vo2max_percentile(29.0, age: 25, sex: :male)
    assert_equal 5.0, @calc.vo2max_percentile(15, age: 25, sex: :male)
  end

  def test_percentile_is_rounded_to_one_decimal
    value = @calc.vo2max_percentile(45, age: 25, sex: :female)
    assert_kind_of Float, value
    assert_equal value.round(1), value
  end

  def test_age_bands_are_decades_used_as_published
    assert_equal 50.0, @calc.vo2max_percentile(42.4, age: 30, sex: :male)
    assert_equal 50.0, @calc.vo2max_percentile(42.4, age: 39, sex: :male)
    refute_equal 50.0, @calc.vo2max_percentile(42.4, age: 29, sex: :male)
  end

  def test_ages_outside_the_table_use_the_nearest_band
    assert_equal @calc.vo2max_percentile(45, age: 25, sex: :male), @calc.vo2max_percentile(45, age: 18, sex: :male)
    assert_equal @calc.vo2max_percentile(25, age: 75, sex: :female),
                 @calc.vo2max_percentile(25, age: 92, sex: :female)
  end

  def test_rejects_minors_and_non_integer_ages
    assert_raises(ArgumentError) { @calc.vo2max_percentile(45, age: 17, sex: :male) }
    assert_raises(ArgumentError) { @calc.vo2max_percentile(45, age: 'old', sex: :male) }
    assert_raises(ArgumentError) { @calc.vo2max_percentile(45, age: nil, sex: :male) }
  end

  def test_sex_accepts_strings_and_rejects_anything_else
    assert_equal @calc.vo2max_percentile(40, age: 30, sex: :female),
                 @calc.vo2max_percentile(40, age: 30, sex: ' Female ')
    assert_raises(ArgumentError) { @calc.vo2max_percentile(40, age: 30, sex: :x) }
    assert_raises(ArgumentError) { @calc.vo2max_percentile(40, age: 30, sex: nil) }
  end

  def test_percentile_rejects_non_positive_values
    assert_raises(Calcpace::NonPositiveInputError) { @calc.vo2max_percentile(0, age: 30, sex: :male) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.vo2max_percentile(-1, age: 30, sex: :male) }
  end

  # --- data file ---

  def test_norms_cover_both_sexes_and_six_decades
    %w[M F].each do |sex|
      assert_equal [20, 30, 40, 50, 60, 70], Vo2maxNorms::VO2MAX_NORMS.fetch(sex).keys.sort
    end
  end

  def test_norms_rows_rise_with_the_percentile
    Vo2maxNorms::VO2MAX_NORMS.each_value do |bands|
      bands.each_value do |row|
        assert_equal Vo2maxNorms::VO2MAX_NORM_PERCENTILES.size, row.size
        assert_equal row.sort.uniq, row
      end
    end
  end

  def test_norms_version_is_exposed
    assert_includes Vo2maxNorms::VO2MAX_NORMS_VERSION, 'FRIEND 2015'
  end
end
