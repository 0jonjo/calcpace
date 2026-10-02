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

  # The gem must read every clock it writes: signed track_splits paces, padded
  # paces past 100 minutes, compact durations past 100 hours and the day
  # prefix of convert_to_clocktime above 24 hours
  def test_convert_to_seconds_reads_the_gems_own_formats
    {
      '-0:40' => -40, '-00:40' => -40, '-5:12' => -312, '-1:06:33' => -3993,
      '123:45' => 7425, '400:00:00' => 1_440_000, '1 03:46:40' => 100_000,
      '12 00:00:00' => 1_036_800, '-1 03:46:40' => -100_000, '0:00' => 0
    }.each do |clock, seconds|
      assert_equal seconds, @calc.convert_to_seconds(clock), clock
      assert_nil @calc.check_time(clock), clock
    end
  end

  def test_malformed_clocks_still_raise
    ['', '-', '--05:00', '+05:00', ' 05:00', '05:00 ', '5:0', '1:5:00', '05:60', '1:60:00',
     '1 3:46:40', '1 24:00:00', '1 03:46', '1 03:60:00', '1  03:46:40', '1:02:03:04', '05:00:',
     "05:00\n", 'abc', '０５:００'].each do |clock|
      assert_raises(Calcpace::InvalidTimeFormatError, clock.inspect) { @calc.convert_to_seconds(clock) }
      assert_raises(Calcpace::InvalidTimeFormatError, clock.inspect) { @calc.check_time(clock) }
    end
  end

  def test_non_strings_are_not_clocks
    [nil, 300, :'05:00'].each do |value|
      assert_raises(Calcpace::InvalidTimeFormatError, value.inspect) { @calc.check_time(value) }
    end
  end

  # A negative clock parses, but every method that needs a positive time or
  # pace still refuses it
  PATHS.each do |name, call|
    define_method(:"test_#{name}_rejects_a_negative_clock") do
      next assert_equal(-300, call.call(@calc, '-05:00')) if name == :convert_to_seconds

      negative = PACE_PATHS.include?(name) ? '-05:00' : '-1:40:00'
      assert_raises(Calcpace::NonPositiveInputError, "#{name} accepted #{negative}") { call.call(@calc, negative) }
    end
  end

  ROUND_TRIP_SECONDS = [0, 1, 40, 59, 60, 61, 312, 3599, 3600, 3993, 5999, 6000, 7425, 35_999, 86_399,
                        86_400, 100_000, 359_999, 360_000, 1_440_000, 1_000_000_007].freeze

  def test_convert_to_clocktime_round_trips_in_both_formats
    (ROUND_TRIP_SECONDS + ROUND_TRIP_SECONDS.map { |s| s + 0.75 }).each do |seconds|
      [false, true].each do |compact|
        clock = @calc.convert_to_clocktime(seconds, compact: compact)
        assert_equal seconds.to_i, @calc.convert_to_seconds(clock), "#{seconds} -> #{clock}"
      end
    end
  end

  def test_track_split_paces_round_trip_in_both_formats
    ROUND_TRIP_SECONDS.flat_map { |s| [s, -s] }.each do |pace|
      [false, true].each do |compact|
        clock = @calc.send(:seconds_to_pace, pace, 1.0, compact: compact)
        assert_equal pace, @calc.convert_to_seconds(clock), "#{pace} -> #{clock}"
      end
    end
  end

  def test_track_splits_output_round_trips_including_backwards_and_slow_splits
    start = Time.utc(2026, 1, 1, 7)
    points = [
      { lat: 0.0, lon: 0.0, time: start },
      { lat: 0.0, lon: 0.009, time: start + 7425 },   # ~1 km in 2:03:45
      { lat: 0.0, lon: 0.018, time: start + 7385 },   # ~1 km, 40 s backwards
      { lat: 0.0, lon: 0.0185, time: start + 7700 }
    ]
    [false, true].each do |compact|
      splits = @calc.track_splits(points, 1.0, compact: compact)
      paces = splits.map { |split| @calc.convert_to_seconds(split[:pace]) }

      assert_predicate paces.min, :negative?, splits.inspect
      assert_operator paces.max, :>, 6000, splits.inspect
      splits.zip(paces).each do |split, seconds|
        assert_equal split[:pace], @calc.send(:seconds_to_pace, seconds, 1.0, compact: compact)
      end
    end
  end

  def test_race_splits_round_trip
    [['marathon', '400:00:00'], ['10k', '00:40:00'], ['marathon', '1 03:46:40'], [100, '99:59:59']].each do |race, time|
      splits = @calc.race_splits(race, target_time: time, split_distance: '5k')
      seconds = splits.map { |clock| @calc.convert_to_seconds(clock) }
      assert_equal seconds.sort, seconds, splits.inspect
      assert_equal @calc.convert_to_seconds(time), seconds.last
    end
  end

  # The clock grammar takes any number of digits, so a clock can parse to an
  # Integer too large for a Float; it must not come back as Infinity
  def test_a_clock_too_large_for_a_float_is_rejected
    huge = "#{'9' * 400}:00:00"

    assert_operator @calc.convert_to_seconds(huge), :>, 10**400
    %i[checked_pace race_pace predict_time race_splits predict_time_cameron age_grade estimate_vo2max].each do |name|
      assert_raises(Calcpace::NonPositiveInputError, name.to_s) { PATHS.fetch(name).call(@calc, huge) }
    end
  end

  def test_strings_in_other_encodings_are_not_clocks
    ['05:00'.encode('UTF-16LE'), '05:00'.encode('UTF-32BE'), (+"05:00\xFF").force_encoding('UTF-8'),
     (+"\xFF05:00").force_encoding('UTF-8')].each do |clock|
      assert_raises(Calcpace::InvalidTimeFormatError, clock.inspect) { @calc.convert_to_seconds(clock) }
      assert_raises(Calcpace::InvalidTimeFormatError, clock.inspect) { @calc.check_time(clock) }
    end
  end

  def test_ascii_compatible_encodings_still_parse
    assert_equal 300, @calc.convert_to_seconds((+'05:00').force_encoding('ASCII-8BIT'))
    assert_equal 300, @calc.convert_to_seconds('05:00'.encode('ISO-8859-1'))
  end
end
