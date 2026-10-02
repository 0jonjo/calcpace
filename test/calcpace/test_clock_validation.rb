# frozen_string_literal: true

require_relative '../test_helper'

# Every public method that reads a time or pace string applies the same clock
# rule as check_time: seconds below 60, and minutes too when hours are given.
# MM:SS keeps counting minutes past the hour ('75:00' is 75 minutes).
class TestClockValidation < CalcpaceTest
  # Each entry builds a call from one clock string, so the same path can be
  # exercised with an invalid clock and with a valid one
  PATHS = {
    convert_to_seconds: ->(c, t) { c.convert_to_seconds(t) },
    checked_pace: ->(c, t) { c.checked_pace(t, 10) },
    checked_velocity: ->(c, t) { c.checked_velocity(t, 10) },
    checked_distance: ->(c, t) { c.checked_distance(t, '00:05:00') },
    race_splits: ->(c, t) { c.race_splits('half_marathon', target_time: t, split_distance: '5k') },
    pace_km_to_mi: ->(c, t) { c.pace_km_to_mi(t) },
    pace_mi_to_km: ->(c, t) { c.pace_mi_to_km(t) },
    convert_pace: ->(c, t) { c.convert_pace(t, :km_to_mi) },
    race_time: ->(c, t) { c.race_time(t, 'marathon') },
    race_time_clock: ->(c, t) { c.race_time_clock(t, 'marathon') },
    race_pace: ->(c, t) { c.race_pace(t, 'marathon') },
    race_pace_clock: ->(c, t) { c.race_pace_clock(t, 'marathon') },
    predict_time: ->(c, t) { c.predict_time('half_marathon', t, 'marathon') },
    predict_time_clock: ->(c, t) { c.predict_time_clock('half_marathon', t, 'marathon') },
    predict_pace: ->(c, t) { c.predict_pace('half_marathon', t, 'marathon') },
    predict_pace_clock: ->(c, t) { c.predict_pace_clock('half_marathon', t, 'marathon') },
    equivalent_performance: ->(c, t) { c.equivalent_performance('half_marathon', t, 'marathon') },
    predict_time_adjusted: ->(c, t) { c.predict_time_adjusted('half_marathon', t, 'marathon', temperature: 25) },
    predict_time_cameron: ->(c, t) { c.predict_time_cameron('half_marathon', t, 'marathon') },
    predict_time_cameron_clock: ->(c, t) { c.predict_time_cameron_clock('half_marathon', t, 'marathon') },
    predict_pace_cameron: ->(c, t) { c.predict_pace_cameron('half_marathon', t, 'marathon') },
    predict_pace_cameron_clock: ->(c, t) { c.predict_pace_cameron_clock('half_marathon', t, 'marathon') },
    predict_time_cameron_adjusted: lambda { |c, t|
      c.predict_time_cameron_adjusted('half_marathon', t, 'marathon', temperature: 25)
    },
    predict_time_personal: ->(c, t) { c.predict_time_personal('10k', '00:45:00', 'half_marathon', t, 'marathon') },
    riegel_exponent: ->(c, t) { c.riegel_exponent('10k', '00:45:00', 'half_marathon', t) },
    predict_marathon_from_training: ->(c, t) { c.predict_marathon_from_training(weekly_distance: 60, training_pace: t) },
    estimate_vo2max: ->(c, t) { c.estimate_vo2max(21.0975, t) },
    estimate_detailed_vo2max: ->(c, t) { c.estimate_detailed_vo2max(21.0975, t) },
    training_paces_from_race: ->(c, t) { c.training_paces_from_race('half_marathon', t) },
    age_grade: ->(c, t) { c.age_grade('half_marathon', t, age: 40, sex: :male) },
    stride_length: ->(c, t) { c.stride_length(t, 170) },
    cadence_for_stride: ->(c, t) { c.cadence_for_stride(t, 1.18) },
    grade_adjusted_pace: ->(c, t) { c.grade_adjusted_pace(t, 0.05) },
    grade_adjusted_pace_clock: ->(c, t) { c.grade_adjusted_pace_clock(t, 0.05) }
  }.freeze

  # A valid clock for each path: paces get a pace, everything else a race time
  PACE_PATHS = %i[pace_km_to_mi pace_mi_to_km convert_pace race_time race_time_clock
                  predict_marathon_from_training stride_length cadence_for_stride
                  grade_adjusted_pace grade_adjusted_pace_clock].freeze

  PATHS.each do |name, call|
    define_method(:"test_#{name}_rejects_seconds_of_sixty_or_more") do
      bad = PACE_PATHS.include?(name) ? '05:99' : '1:40:99'
      assert_raises(Calcpace::InvalidTimeFormatError, "#{name} accepted #{bad}") { call.call(@calc, bad) }
    end

    define_method(:"test_#{name}_rejects_minutes_of_sixty_or_more_with_hours") do
      assert_raises(Calcpace::InvalidTimeFormatError, "#{name} accepted 1:60:00") { call.call(@calc, '1:60:00') }
    end

    define_method(:"test_#{name}_accepts_a_valid_clock") do
      good = PACE_PATHS.include?(name) ? '05:00' : '1:40:00'
      call.call(@calc, good)
    end
  end

  def test_minutes_past_the_hour_stay_valid_in_mm_ss
    assert_equal 4500, @calc.convert_to_seconds('75:00')
    assert_equal '01:15:00', @calc.race_splits('10k', target_time: '75:00', split_distance: '10k').last
    assert_in_delta 450.0, @calc.race_pace('75:00', '10k')
    assert_equal '00:12:04', @calc.pace_km_to_mi('07:30')
    assert_operator @calc.predict_time('10k', '75:00', 'half_marathon'), :>, 4500
  end

  def test_numeric_inputs_are_not_affected
    assert_in_delta 450.0, @calc.race_pace(4500, '10k')
    assert_equal '00:08:02', @calc.convert_pace(300, :km_to_mi)
  end

  def test_garbage_strings_raise_instead_of_becoming_zero_seconds
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.convert_to_seconds('abc') }
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.race_splits('10k', target_time: '40', split_distance: '5k') }
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.predict_time('5k', '20:00:00:00', '10k') }
  end
end
