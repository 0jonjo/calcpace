# frozen_string_literal: true

require_relative '../test_helper'

# Tests for predictions built from the runner's own data: training volume
# (Tanda 2011) and a personal Riegel exponent fitted to two performances
class TestPersonalizedPredictor < CalcpaceTest
  # --- Tanda (2011): marathon from training volume ---------------------------

  # Pm = 17.1 + 140.0 * exp(-0.0053 * 60) + 0.55 * 300 = 283.96 s/km
  def test_marathon_from_training_applies_the_tanda_equation
    result = @calc.predict_marathon_from_training(weekly_distance: 60, training_pace: 300)

    assert_in_delta 283.96, result[:pace], 0.01
    assert_in_delta 283.9644 * 42.195, result[:time], 0.01
    assert_equal '03:19:41', result[:time_clock]
    assert_equal '00:04:43', result[:pace_clock]
  end

  def test_the_sample_means_reproduce_the_sample_mean_marathon_pace
    # Table 2 of the paper: K = 65.9 km/week and P = 284.6 s/km on average,
    # mean race pace 271.8 s/km. A regression evaluated at the means of its own
    # predictors has to land next to the mean of its response.
    result = @calc.predict_marathon_from_training(weekly_distance: 65.9, training_pace: 284.6)

    assert_in_delta 271.8, result[:pace], 1.0
  end

  def test_training_pace_accepts_a_clock_string
    numeric = @calc.predict_marathon_from_training(weekly_distance: 60, training_pace: 300)
    clock = @calc.predict_marathon_from_training(weekly_distance: 60, training_pace: '05:00')

    assert_equal numeric, clock
  end

  def test_more_volume_and_faster_training_both_predict_a_faster_marathon
    base = @calc.predict_marathon_from_training(weekly_distance: 50, training_pace: 300)[:time]
    more_volume = @calc.predict_marathon_from_training(weekly_distance: 80, training_pace: 300)[:time]
    faster_training = @calc.predict_marathon_from_training(weekly_distance: 50, training_pace: 280)[:time]

    assert_operator more_volume, :<, base
    assert_operator faster_training, :<, base
  end

  def test_inputs_inside_the_paper_sample_are_flagged_as_validated
    result = @calc.predict_marathon_from_training(weekly_distance: 60, training_pace: 300)

    assert result[:within_validated_range]
    assert_empty result[:out_of_range]
  end

  def test_low_volume_is_flagged_but_still_predicted
    # 40 km/week is just under the sample minimum of 40.4 km/week, and the
    # resulting 3:39 marathon is slower than the slowest one in the sample (3:36)
    result = @calc.predict_marathon_from_training(weekly_distance: 40, training_pace: '05:30')

    refute result[:within_validated_range]
    assert_equal %i[weekly_distance marathon_time], result[:out_of_range]
    assert_equal '03:39:18', result[:time_clock]
  end

  def test_slow_training_pace_is_flagged
    result = @calc.predict_marathon_from_training(weekly_distance: 25, training_pace: '06:30')

    refute result[:within_validated_range]
    assert_equal %i[weekly_distance training_pace marathon_time], result[:out_of_range]
  end

  def test_fast_training_pace_is_flagged
    result = @calc.predict_marathon_from_training(weekly_distance: 100, training_pace: '04:00')

    assert_includes result[:out_of_range], :training_pace
  end

  def test_boundaries_of_the_sample_are_inside_the_validated_range
    low = @calc.predict_marathon_from_training(weekly_distance: 40.4, training_pace: 330.6)
    high = @calc.predict_marathon_from_training(weekly_distance: 110.7, training_pace: 253.3)

    refute_includes low[:out_of_range], :weekly_distance
    refute_includes low[:out_of_range], :training_pace
    refute_includes high[:out_of_range], :weekly_distance
    refute_includes high[:out_of_range], :training_pace
  end

  def test_miles_convert_both_inputs_and_report_pace_per_mile
    # 25 mi/week at 8:00/mi is 40.23 km/week at 298.26 s/km
    result = @calc.predict_marathon_from_training(weekly_distance: 25, training_pace: '08:00', unit: :mi)
    km = @calc.predict_marathon_from_training(weekly_distance: 25 * 1.609344, training_pace: 480 / 1.609344)

    assert_in_delta km[:time], result[:time], 0.01
    assert_in_delta km[:pace] * 1.609344, result[:pace], 0.01
    assert_in_delta 473.56, result[:pace], 0.01
    assert_equal '00:07:53', result[:pace_clock]
    assert_equal km[:out_of_range], result[:out_of_range]
  end

  def test_unit_is_case_insensitive
    upper = @calc.predict_marathon_from_training(weekly_distance: 25, training_pace: 480, unit: 'MI')
    lower = @calc.predict_marathon_from_training(weekly_distance: 25, training_pace: 480, unit: :mi)

    assert_equal lower, upper
  end

  def test_unsupported_unit_raises
    assert_raises(Calcpace::UnsupportedUnitError) do
      @calc.predict_marathon_from_training(weekly_distance: 60, training_pace: 300, unit: :furlong)
    end
  end

  def test_non_positive_inputs_raise
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.predict_marathon_from_training(weekly_distance: 0, training_pace: 300)
    end
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.predict_marathon_from_training(weekly_distance: 60, training_pace: -1)
    end
  end

  def test_malformed_training_pace_raises_invalid_time_format
    ['5:3x', 'abc', '', :'05:00', nil].each do |pace|
      assert_raises(Calcpace::InvalidTimeFormatError, "expected #{pace.inspect} to be rejected") do
        @calc.predict_marathon_from_training(weekly_distance: 60, training_pace: pace)
      end
    end
  end

  def test_numeric_string_weekly_distance_is_accepted
    string = @calc.predict_marathon_from_training(weekly_distance: '60', training_pace: 300)
    numeric = @calc.predict_marathon_from_training(weekly_distance: 60, training_pace: 300)

    assert_equal numeric, string
  end

  def test_non_numeric_weekly_distance_raises
    ['abc', '', nil, :'60'].each do |distance|
      assert_raises(Calcpace::NonPositiveInputError, "expected #{distance.inspect} to be rejected") do
        @calc.predict_marathon_from_training(weekly_distance: distance, training_pace: 300)
      end
    end
  end

  def test_non_finite_inputs_raise
    [Float::INFINITY, Float::NAN].each do |value|
      assert_raises(Calcpace::NonPositiveInputError) do
        @calc.predict_marathon_from_training(weekly_distance: value, training_pace: 300)
      end
      assert_raises(Calcpace::NonPositiveInputError) do
        @calc.predict_marathon_from_training(weekly_distance: 60, training_pace: value)
      end
    end
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.predict_marathon_from_training(weekly_distance: 'Infinity', training_pace: 300)
    end
  end

  # --- Personal Riegel exponent ----------------------------------------------

  def test_riegel_exponent_from_two_performances
    # ln(6120 / 2700) / ln(21.0975 / 10)
    exponent = @calc.riegel_exponent('10k', '00:45:00', 'half_marathon', '01:42:00')

    assert_in_delta 1.096094, exponent, 1e-6
  end

  def test_riegel_exponent_recovers_the_standard_exponent
    half = @calc.predict_time('10k', 2700, 'half_marathon')

    assert_in_delta 1.06, @calc.riegel_exponent('10k', 2700, 'half_marathon', half), 1e-9
  end

  def test_riegel_exponent_does_not_depend_on_order
    forward = @calc.riegel_exponent('10k', '00:45:00', 'half_marathon', '01:42:00')
    backward = @calc.riegel_exponent('half_marathon', '01:42:00', '10k', '00:45:00')

    assert_in_delta forward, backward, 1e-12
  end

  def test_riegel_exponent_accepts_numeric_distances_and_seconds
    named = @calc.riegel_exponent('5k', '00:20:00', '10k', '00:42:00')
    numeric = @calc.riegel_exponent(5, 1200, '10', 2520)

    assert_in_delta named, numeric, 1e-12
  end

  def test_riegel_exponent_rejects_the_same_distance
    assert_error_with_message(ArgumentError, 'different distances') do
      @calc.riegel_exponent('10k', '00:45:00', 10, '00:46:00')
    end
  end

  def test_riegel_exponent_rejects_unknown_race_and_non_positive_time
    assert_raises(ArgumentError) { @calc.riegel_exponent('10q', 2700, '5k', 1300) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.riegel_exponent('10k', 0, '5k', 1300) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.riegel_exponent('10k', Float::INFINITY, '5k', 1300) }
  end

  def test_malformed_race_times_raise_invalid_time_format
    ['45:0x', 'abc', :'00:45:00', nil].each do |time|
      assert_raises(Calcpace::InvalidTimeFormatError, "expected #{time.inspect} to be rejected") do
        @calc.riegel_exponent('10k', time, '5k', 1300)
      end
      assert_raises(Calcpace::InvalidTimeFormatError) do
        @calc.predict_time_personal('10k', 2700, '5k', time, 'marathon')
      end
    end
  end

  def test_personal_prediction_uses_the_performance_closest_to_the_target
    # The half marathon is closer to the marathon than the 10K, so the
    # prediction scales 1:42:00 by (42.195 / 21.0975)^1.096094
    result = @calc.predict_time_personal('10k', '00:45:00', 'half_marathon', '01:42:00', 'marathon')

    assert_in_delta 6120 * (2**1.096094), result[:time], 0.1
    assert_equal '03:38:03', result[:time_clock]
    assert_in_delta 1.0961, result[:exponent], 1e-4
    assert_in_delta 1.0961, result[:raw_exponent], 1e-4
    refute result[:clamped]
  end

  def test_personal_prediction_anchor_does_not_depend_on_argument_order
    forward = @calc.predict_time_personal('10k', '00:45:00', 'half_marathon', '01:42:00', '5k')
    backward = @calc.predict_time_personal('half_marathon', '01:42:00', '10k', '00:45:00', '5k')

    assert_in_delta forward[:time], backward[:time], 1e-6
    # 5K is anchored on the 10K: 2700 * (5 / 10)^1.096094
    assert_in_delta 2700 * (0.5**1.096094), forward[:time], 0.1
  end

  def test_an_implausibly_low_exponent_is_clamped
    # A 10K at 3:00/km followed by a half at the same pace: k = 1.0
    result = @calc.predict_time_personal('10k', 1800, 'half_marathon', 3797.55, 'marathon')

    assert result[:clamped]
    assert_in_delta 1.0, result[:raw_exponent], 1e-4
    assert_in_delta 1.01, result[:exponent], 1e-12
    assert_in_delta 3797.55 * (2**1.01), result[:time], 0.1
  end

  def test_an_implausibly_high_exponent_is_clamped
    result = @calc.predict_time_personal('5k', '00:20:00', '10k', '00:50:00', 'half_marathon')

    assert result[:clamped]
    assert_operator result[:raw_exponent], :>, 1.2
    assert_in_delta 1.2, result[:exponent], 1e-12
  end

  def test_a_longer_race_run_faster_is_clamped_not_raised
    result = @calc.predict_time_personal('5k', '00:25:00', '10k', '00:24:00', 'marathon')

    assert result[:clamped]
    assert_operator result[:raw_exponent], :<, 0
    assert_in_delta 1.01, result[:exponent], 1e-12
  end

  def test_a_target_between_the_two_races_uses_the_raw_exponent
    # k = ln(3000 / 1200) / ln(20 / 5) = 0.661, far below the clamp: but the 10K
    # lies between the two known races, so the curve through both of them is
    # used as is — clamping would contradict the runner's own data
    result = @calc.predict_time_personal(5, 1200, 20, 3000, 10)

    refute result[:clamped]
    assert_in_delta 0.6610, result[:exponent], 1e-4
    assert_equal result[:raw_exponent], result[:exponent]
    assert_in_delta 1200 * (2**(Math.log(2.5) / Math.log(4))), result[:time], 0.01
  end

  def test_interpolation_does_not_depend_on_argument_order
    # 10 km is the geometric mean of 5 and 20: both races are equally close
    forward = @calc.predict_time_personal(5, 1200, 20, 3000, 10)
    backward = @calc.predict_time_personal(20, 3000, 5, 1200, 10)

    assert_equal forward, backward
  end

  def test_interpolation_passes_through_both_known_performances
    # Between a 10K in 45:00 and a half in 1:42:00, a 15K sits on the same
    # curve whichever performance it is scaled from
    result = @calc.predict_time_personal('10k', '00:45:00', 'half_marathon', '01:42:00', 15)
    exponent = Math.log(6120.0 / 2700) / Math.log(21.0975 / 10)

    assert_in_delta 2700 * (1.5**exponent), result[:time], 0.01
    assert_in_delta 6120 * ((15 / 21.0975)**exponent), result[:time], 0.01
  end

  def test_extrapolation_outside_the_pair_is_still_clamped
    result = @calc.predict_time_personal(5, 1200, 20, 3000, 'marathon')

    assert result[:clamped]
    assert_in_delta 1.01, result[:exponent], 1e-12
    assert_in_delta 3000 * ((42.195 / 20)**1.01), result[:time], 0.01
  end

  def test_personal_prediction_rejects_a_target_already_known
    assert_raises(ArgumentError) do
      @calc.predict_time_personal('10k', '00:45:00', 'half_marathon', '01:42:00', 'half_marathon')
    end
  end

  def test_personal_prediction_rejects_two_performances_at_the_same_distance
    assert_raises(ArgumentError) do
      @calc.predict_time_personal('10k', '00:45:00', '10k', '00:44:00', 'marathon')
    end
  end
end
