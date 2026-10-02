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
end
