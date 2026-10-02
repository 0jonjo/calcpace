# frozen_string_literal: true

require_relative '../test_helper'

class TestChecker < CalcpaceTest
  def test_check_positive
    assert_raises(Calcpace::NonPositiveInputError) { @calc.check_positive(-1) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.check_positive(0) }
    assert_nil @calc.check_positive(1)
  end

  def test_check_positive_rejects_non_finite_numbers
    assert_raises(Calcpace::NonPositiveInputError) { @calc.check_positive(Float::INFINITY) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.check_positive(-Float::INFINITY) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.check_positive(Float::NAN) }
    assert_nil @calc.check_positive(1e300)
    assert_nil @calc.check_positive(Rational(1, 3))
  end

  def test_check_positive_names_the_input_when_it_is_not_finite
    assert_error_with_message(Calcpace::NonPositiveInputError, 'Distance must be a finite positive number') do
      @calc.check_positive(Float::INFINITY, 'Distance')
    end
  end

  def test_check_time
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.check_time('') }
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.check_time('1-2-3') }
    assert_nil @calc.check_time('00:00:00')
  end

  def test_check_time_accepts_valid_clocks
    %w[05:00 5:00 05:59 1:05:00 01:05:00 23:59:59 99:59:59 0:00].each do |time|
      assert_nil @calc.check_time(time), "expected #{time} to be valid"
    end
  end

  # MM:SS keeps counting minutes past the hour: '75:00' is a 75-minute run and
  # track_splits itself emits paces like '66:33' in the padded format
  def test_check_time_accepts_minutes_past_the_hour_in_mm_ss
    %w[60:00 66:33 75:00 99:59].each do |time|
      assert_nil @calc.check_time(time), "expected #{time} to be valid"
    end
  end

  def test_check_time_rejects_seconds_of_sixty_or_more
    %w[05:60 05:99 19:99 1:00:60 01:30:99].each do |time|
      assert_raises(Calcpace::InvalidTimeFormatError, "expected #{time} to be invalid") { @calc.check_time(time) }
    end
  end

  def test_check_time_rejects_minutes_of_sixty_or_more_when_hours_are_given
    %w[1:60:00 01:75:00 0:99:59].each do |time|
      assert_raises(Calcpace::InvalidTimeFormatError, "expected #{time} to be invalid") { @calc.check_time(time) }
    end
  end

  def test_invalid_clock_is_rejected_by_public_methods
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.checked_pace('00:19:99', 5) }
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.checked_velocity('1:60:00', 10) }
  end

  # A bignum is finite, but one too large for a Float overflows to Infinity as
  # soon as a formula calls to_f on it
  def test_check_positive_rejects_integers_that_overflow_a_float
    assert_error_with_message(Calcpace::NonPositiveInputError, 'Time must be a finite positive number') do
      @calc.check_positive(10**400, 'Time')
    end
    assert_nil @calc.check_positive(10**300)
  end
end
