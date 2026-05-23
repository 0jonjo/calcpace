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
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.estimate_vo2max(10.0, 'fast') }
  end

  def test_raises_for_non_numeric_time_segments
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.estimate_vo2max(10.0, '00:aa:00') }
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

  # --- estimate_detailed_vo2max ---

  def test_detailed_vo2max_returns_struct_with_correct_data
    result = @calc.estimate_detailed_vo2max(10.0, '00:40:00')
    assert_respond_to result, :value
    assert_respond_to result, :confidence
    assert_respond_to result, :sub_maximal
    assert_respond_to result, :adjusted_distance_km
    assert_equal 51.9, result.value
    assert_equal :high, result.confidence
    assert_equal false, result.sub_maximal
    assert_equal 10.0, result.adjusted_distance_km
  end

  def test_detailed_vo2max_confidence_high_for_10k
    result = @calc.estimate_detailed_vo2max(10.0, '00:40:00')
    assert_equal :high, result.confidence
  end

  def test_detailed_vo2max_confidence_medium_for_half_marathon
    result = @calc.estimate_detailed_vo2max(21.0975, '01:40:00')
    assert_equal :medium, result.confidence
  end

  def test_detailed_vo2max_confidence_low_for_marathon
    result = @calc.estimate_detailed_vo2max(42.195, '04:00:00')
    assert_equal :low, result.confidence
  end

  def test_detailed_vo2max_elevation_adjustment_increases_value
    flat_result = @calc.estimate_detailed_vo2max(10.0, '00:40:00')
    hilly_result = @calc.estimate_detailed_vo2max(10.0, '00:40:00', elevation_gain_m: 100)

    assert hilly_result.value > flat_result.value
    assert_equal 10.6, hilly_result.adjusted_distance_km # 10km + 100m * 6 = 10.6km
  end

  def test_detailed_vo2max_sub_maximal_detection
    # HR intensity = 140 / 200 = 70% (< 85%)
    result = @calc.estimate_detailed_vo2max(10.0, '00:40:00', hr_avg: 140, hr_max: 200)
    assert_equal true, result.sub_maximal
    assert_equal :low, result.confidence
  end

  def test_detailed_vo2max_maximal_effort_detection
    # HR intensity = 180 / 200 = 90% (> 85%)
    result = @calc.estimate_detailed_vo2max(10.0, '00:40:00', hr_avg: 180, hr_max: 200)
    assert_equal false, result.sub_maximal
    assert_equal :high, result.confidence
  end

  def test_detailed_vo2max_confidence_low_for_short_effort
    # < 5 min has high anaerobic contribution — outside Daniels & Gilbert optimal window
    result = @calc.estimate_detailed_vo2max(1.0, '00:04:00')
    assert_equal :low, result.confidence
  end

  def test_detailed_vo2max_raises_when_hr_avg_exceeds_hr_max
    assert_raises(Calcpace::Error) do
      @calc.estimate_detailed_vo2max(10.0, '00:40:00', hr_avg: 210, hr_max: 200)
    end
  end
end
