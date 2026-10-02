# frozen_string_literal: true

require_relative '../test_helper'

# Test race time predictions using the Cameron formula
class TestCameronPredictor < CalcpaceTest
  # ── predict_time_cameron ──────────────────────────────────────────────────

  def test_predict_time_5k_to_10k
    # 5K in 20:00 → 10K
    # Cameron formula: 1200 × (10000/5000) × [f(5000) / f(10000)] ≈ 2499.66s ≈ 41:39
    result = @calc.predict_time_cameron('5k', '00:20:00', '10k')

    assert_in_delta 2499.66, result, 0.01
  end

  def test_predict_time_10k_to_half_marathon
    result = @calc.predict_time_cameron('10k', '00:42:00', 'half_marathon')

    # Should land in a reasonable half marathon range for a 42:00 10K runner
    assert result > 5000, 'Half marathon should be over 1:23'
    assert result < 6000, 'Half marathon should be under 1:40'
  end

  def test_predict_time_10k_to_marathon
    # 10K in 42:00 → marathon ≈ 11,806.76s (3:16:46)
    result = @calc.predict_time_cameron('10k', '00:42:00', 'marathon')

    assert_in_delta 11_806.76, result, 0.01
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
    assert_equal '03:16:46', @calc.predict_time_cameron_clock('10k', '00:42:00', 'marathon')
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

  def test_cameron_is_more_conservative_than_riegel_for_the_marathon_from_5k
    cameron = @calc.predict_time_cameron('5k', '00:20:00', 'marathon')
    riegel  = @calc.predict_time('5k', '00:20:00', 'marathon')

    assert_operator cameron, :>, riegel, 'Cameron 5K→marathon should be slower than Riegel'
  end

  def test_cameron_is_more_conservative_than_riegel_for_the_marathon_from_10k
    cameron = @calc.predict_time_cameron('10k', '00:42:00', 'marathon')
    riegel  = @calc.predict_time('10k', '00:42:00', 'marathon')

    assert_operator cameron, :>, riegel, 'Cameron 10K→marathon should be slower than Riegel'
  end

  # ── reference predictions (Cameron's metric model) ───────────────────────

  def test_reference_5k_to_marathon
    # 5K 20:00 → marathon ≈ 3:15:11
    assert_in_delta 11_711.47, @calc.predict_time_cameron('5k', '00:20:00', 'marathon'), 0.01
  end

  def test_reference_half_marathon_to_marathon
    # Half 1:30:00 → marathon ≈ 3:11:15
    assert_in_delta 11_475.12, @calc.predict_time_cameron('half_marathon', '01:30:00', 'marathon'), 0.01
  end

  def test_reference_marathon_to_5k
    # Marathon 3:30:00 → 5K ≈ 21:31
    assert_in_delta 1291.04, @calc.predict_time_cameron('marathon', '03:30:00', '5k'), 0.01
  end

  def test_reference_matches_had2know_worked_example
    # had2know.org Cameron page: 3.5 mi (5632.704 m) in 51:30 → 5 mi (8046.72 m) ≈ 75:08
    result = @calc.predict_time_cameron(5.632704, '00:51:30', 8.04672)

    assert_equal '01:15:08', @calc.convert_to_clocktime(result)
  end

  def test_velocity_function_matches_published_constants
    # f(d) = 13.49681 − 0.000030363·d + 835.7114 / d^0.7905, d in metres
    expected = 13.49681 - (0.000030363 * 10_000) + (835.7114 / (10_000**0.7905))

    assert_in_delta expected, @calc.send(:cameron_factor, 10.0), 1e-12
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

  # ── valid distance range ─────────────────────────────────────────────────
  # f(d) crosses zero near 445 km, so beyond the fitted range the formula returns
  # negative or absurd times. Distances above CAMERON_MAX_DISTANCE_KM raise.

  CAMERON_VARIANTS = %i[predict_time_cameron predict_time_cameron_clock
                        predict_pace_cameron predict_pace_cameron_clock
                        predict_time_cameron_adjusted].freeze

  def test_max_distance_constant
    assert_in_delta 100.0, CameronPredictor::CAMERON_MAX_DISTANCE_KM, 0.0
  end

  def test_max_distance_is_accepted_as_source_and_target
    CAMERON_VARIANTS.each do |method|
      @calc.public_send(method, 100, '08:00:00', 'marathon')
      @calc.public_send(method, '100k', '08:00:00', 'marathon')
      @calc.public_send(method, 'marathon', '03:30:00', 100)
      @calc.public_send(method, 'marathon', '03:30:00', '100k')
    end
  end

  def test_max_distance_prediction_is_sane
    # Marathon 3:30:00 → 100 km should be slower than 2.37× the marathon time
    result = @calc.predict_time_cameron('marathon', '03:30:00', '100k')

    assert_operator result, :>, 12_600 * (100 / 42.195)
  end

  def test_distances_above_the_max_raise_as_source
    [100.1, 445.5, 1000].each do |distance|
      CAMERON_VARIANTS.each do |method|
        error = assert_raises(ArgumentError, "#{method} from #{distance} km") do
          @calc.public_send(method, distance, '10:00:00', 'marathon')
        end
        assert_match(/Cameron.*100\.0 km/, error.message)
      end
    end
  end

  def test_distances_above_the_max_raise_as_target
    [100.1, 445.5, 1000].each do |distance|
      CAMERON_VARIANTS.each do |method|
        error = assert_raises(ArgumentError, "#{method} to #{distance} km") do
          @calc.public_send(method, '10k', '00:42:00', distance)
        end
        assert_match(/Cameron.*100\.0 km/, error.message)
      end
    end
  end

  # ── adjusted predictions ───────────────────────────────────────────────────

  def test_predict_time_cameron_adjusted_with_heat
    # 5K in 20:00 to 10K
    # Normal Cameron: ~2499.66s
    # Duration factor for ~41:40 (2499.66s) is ~0.694x
    # Adjusted for 20°C (Base 2.8% * 0.694 ≈ 1.94% penalty): 2499.66 * 1.0194 ≈ 2548.15s
    result = @calc.predict_time_cameron_adjusted('5k', '00:20:00', '10k', temperature: 20)

    assert_kind_of Hash, result
    assert_in_delta 2548.15, result[:adjusted_time], 0.01
    assert_equal 1.94, result[:penalty_percent]
  end

  # --- free distances (v1.15.0) ---

  def test_predict_time_cameron_accepts_a_free_distance
    # Alagoas Abel: 7.79 km in 26:59 -> half marathon
    result = @calc.predict_time_cameron(7.79, '00:26:59', 'half_marathon')

    assert_in_delta 4646.36, result, 0.01
  end

  def test_predict_time_cameron_numeric_distance_matches_the_named_race
    assert_equal @calc.predict_time_cameron('10k', '00:42:00', 'marathon'),
                 @calc.predict_time_cameron(10.0, '00:42:00', 42.195)
  end

  def test_predict_pace_cameron_accepts_a_free_distance
    seconds = @calc.predict_time_cameron(7.79, 1619, 15.0)

    assert_in_delta seconds / 15.0, @calc.predict_pace_cameron(7.79, 1619, 15.0), 0.001
  end

  def test_predict_time_cameron_rejects_the_same_numeric_distance
    assert_raises(ArgumentError) { @calc.predict_time_cameron(7.79, 1619, 7.79) }
    assert_raises(ArgumentError) { @calc.predict_time_cameron(10.0, 2520, '10k') }
    assert_raises(ArgumentError) { @calc.predict_time_cameron(10.0, 2520, 10.0 + 1e-12) }
  end

  def test_predict_time_cameron_rejects_non_positive_numeric_distances
    assert_raises(Calcpace::NonPositiveInputError) { @calc.predict_time_cameron(0, 1619, '10k') }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.predict_time_cameron('10k', 2520, -5) }
  end
end
