# frozen_string_literal: true

require_relative '../test_helper'

class TestChecker < CalcpaceTest
  def test_check_positive
    assert_raises(Calcpace::NonPositiveInputError) { @calc.check_positive(-1) }
    assert_raises(Calcpace::NonPositiveInputError) { @calc.check_positive(0) }
    assert_nil @calc.check_positive(1)
  end

  def test_check_time
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.check_time('') }
    assert_raises(Calcpace::InvalidTimeFormatError) { @calc.check_time('1-2-3') }
    assert_nil @calc.check_time('00:00:00')
  end
end
