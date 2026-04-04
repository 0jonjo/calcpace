# frozen_string_literal: true

require_relative '../test_helper'

# Tests for Vo2maxEstimator module — Daniels & Gilbert formula
class TestVo2maxEstimator < CalcpaceTest
  # --- estimate_vo2max ---

  def test_10k_in_40min_returns_expected_value
    result = @calc.estimate_vo2max(10.0, '00:40:00')
    assert_in_delta 51.9, result, 0.5
  end

  def test_5k_in_20min_returns_plausible_value
    result = @calc.estimate_vo2max(5.0, '00:20:00')
    assert_in_delta 49.8, result, 0.5
  end

  def test_marathon_in_3h30_returns_plausible_value
    result = @calc.estimate_vo2max(42.195, '03:30:00')
    assert_in_delta 45.0, result, 2.0
  end

  def test_accepts_mm_ss_format
    result = @calc.estimate_vo2max(5.0, '20:00')
    assert_kind_of Float, result
    assert result.positive?
  end

  def test_accepts_time_in_seconds
    result_str = @calc.estimate_vo2max(10.0, '00:40:00')
    result_int = @calc.estimate_vo2max(10.0, 2400)
    assert_in_delta result_str, result_int, 0.1
  end

  def test_returns_float_rounded_to_one_decimal
    result = @calc.estimate_vo2max(10.0, '00:40:00')
    assert_instance_of Float, result
    assert_equal result, result.round(1)
  end

  def test_raises_for_zero_distance
    assert_raises(Calcpace::NonPositiveInputError) { @calc.estimate_vo2max(0, '00:40:00') }
  end

  def test_raises_for_zero_time
    assert_raises(Calcpace::NonPositiveInputError) { @calc.estimate_vo2max(10.0, 0) }
  end

  def test_raises_for_invalid_time_format
    assert_raises(ArgumentError) { @calc.estimate_vo2max(10.0, 'fast') }
  end

  # --- vo2max_label ---

  def test_label_elite
    assert_equal 'Elite', @calc.vo2max_label(72.0)
  end

  def test_label_excellent
    assert_equal 'Excellent', @calc.vo2max_label(65.0)
  end

  def test_label_very_good
    assert_equal 'Very Good', @calc.vo2max_label(52.0)
  end

  def test_label_good
    assert_equal 'Good', @calc.vo2max_label(45.0)
  end

  def test_label_fair
    assert_equal 'Fair', @calc.vo2max_label(35.0)
  end

  def test_label_beginner
    assert_equal 'Beginner', @calc.vo2max_label(25.0)
  end

  def test_label_raises_for_non_positive_value
    assert_raises(Calcpace::NonPositiveInputError) { @calc.vo2max_label(0) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.vo2max_label(-5) }
  end

  def test_estimate_and_label_integrate_for_10k_in_40min
    vo2max = @calc.estimate_vo2max(10.0, '00:40:00')
    assert_equal 'Very Good', @calc.vo2max_label(vo2max)
  end
end
