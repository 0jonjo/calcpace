# frozen_string_literal: true

require_relative '../test_helper'

# Test race time predictions using the Cameron formula
class TestCameronPredictor < CalcpaceTest
  # ── predict_time_cameron ──────────────────────────────────────────────────

  def test_predict_time_5k_to_10k
    # 5K in 20:00 → 10K
    # Cameron formula: 1200 × (10/5) × [factor(5) / factor(10)] ≈ 2544s ≈ 42:24
    result = @calc.predict_time_cameron('5k', '00:20:00', '10k')

    assert_in_delta 2544, result, 10
  end

  def test_predict_time_10k_to_half_marathon
    result = @calc.predict_time_cameron('10k', '00:42:00', 'half_marathon')

    # Should land in a reasonable half marathon range for a 42:00 10K runner
    assert result > 5000, 'Half marathon should be over 1:23'
    assert result < 6000, 'Half marathon should be under 1:40'
  end

  def test_predict_time_10k_to_marathon
    # 10K in 42:00 → marathon
    result = @calc.predict_time_cameron('10k', '00:42:00', 'marathon')

    assert_in_delta 10_666, result, 100
  end

  def test_predict_time_half_to_marathon
    result = @calc.predict_time_cameron('half_marathon', '01:30:00', 'marathon')

    # Half marathon in 1:30 → marathon prediction should be between 3:00 and 3:20
    assert result > 10_800, 'Marathon should be over 3:00'
    assert result < 12_000, 'Marathon should be under 3:20'
  end

  def test_predict_time_with_numeric_input
    # Seconds input should produce same result as HH:MM:SS string
    string_result = @calc.predict_time_cameron('5k', '00:20:00', '10k')
    numeric_result = @calc.predict_time_cameron('5k', 1200, '10k')

    assert_in_delta string_result, numeric_result, 1
  end

  def test_predict_time_with_mmss_format
    # MM:SS format should produce same result as HH:MM:SS
    string_result  = @calc.predict_time_cameron('5k', '00:20:00', '10k')
    mmss_result    = @calc.predict_time_cameron('5k', '20:00', '10k')

    assert_in_delta string_result, mmss_result, 1
  end

  def test_predict_time_reverse_direction
    # Predicting shorter from longer should return a faster time
    result = @calc.predict_time_cameron('marathon', '03:30:00', '5k')

    # Should be under 25:00 for a 3:30 marathoner
    assert result < 1500, '5K time should be under 25:00'
    assert result > 900,  '5K time should be over 15:00'
  end

  # ── predict_time_cameron_clock ────────────────────────────────────────────

  def test_predict_time_clock_returns_hhmmss
    result = @calc.predict_time_cameron_clock('10k', '00:42:00', 'marathon')

    assert_match(/^\d{2}:\d{2}:\d{2}$/, result)
  end

  def test_predict_time_clock_10k_to_marathon
    result = @calc.predict_time_cameron_clock('10k', '00:42:00', 'marathon')

    parts = result.split(':').map(&:to_i)
    assert_equal 2, parts[0], 'Should be 2 hours'
  end

  # ── predict_pace_cameron ──────────────────────────────────────────────────

  def test_predict_pace_marathon_is_slower_than_5k
    pace_marathon = @calc.predict_pace_cameron('5k', '00:20:00', 'marathon')

    # Marathon pace should be slower (more seconds per km) than 5K pace (4:00/km = 240s/km)
    actual_5k_pace = 1200.0 / 5
    assert pace_marathon > actual_5k_pace, 'Marathon pace should be slower than 5K pace'
  end

  def test_predict_pace_cameron_clock_returns_hhmmss
    result = @calc.predict_pace_cameron_clock('10k', '00:42:00', 'marathon')

    assert_match(/^\d{2}:\d{2}:\d{2}$/, result)
  end

  # ── difference with Riegel ────────────────────────────────────────────────

  def test_cameron_differs_from_riegel
    cameron = @calc.predict_time_cameron('5k', '00:20:00', 'marathon')
    riegel  = @calc.predict_time('5k', '00:20:00', 'marathon')

    # Both should give a valid marathon prediction (between 2:30 and 5:00)
    assert cameron > 9_000
    assert cameron < 18_000
    assert riegel > 9_000
    assert riegel < 18_000
    refute_in_delta cameron, riegel, 1, 'Cameron and Riegel should produce different predictions'
  end

  # ── consistency ──────────────────────────────────────────────────────────

  def test_round_trip_consistency
    original_time = 1200.0 # 20:00 5K
    predicted_10k = @calc.predict_time_cameron('5k', original_time, '10k')
    back_to_5k    = @calc.predict_time_cameron('10k', predicted_10k, '5k')

    assert_in_delta original_time, back_to_5k, 5
  end

  # ── error handling ────────────────────────────────────────────────────────

  def test_same_distance_raises
    error = assert_raises(ArgumentError) do
      @calc.predict_time_cameron('10k', '00:42:00', '10k')
    end
    assert_match(/must be different/, error.message)
  end

  def test_invalid_from_race_raises
    assert_raises(ArgumentError) do
      @calc.predict_time_cameron('invalid', '00:20:00', '10k')
    end
  end

  def test_invalid_to_race_raises
    assert_raises(ArgumentError) do
      @calc.predict_time_cameron('5k', '00:20:00', 'invalid')
    end
  end

  def test_negative_time_raises
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.predict_time_cameron('5k', -1200, '10k')
    end
  end

  def test_zero_time_raises
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.predict_time_cameron('5k', 0, '10k')
    end
  end
end
