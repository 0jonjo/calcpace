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
    assert_equal 'Developing', @calc.age_grade_label(55.0)
    assert_equal 'Developing', @calc.age_grade_label(0.0)
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
end
