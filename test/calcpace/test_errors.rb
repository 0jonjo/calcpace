# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/calcpace'

# Test custom error classes
class TestErrors < Minitest::Test
  def setup
    @calc = Calcpace.new
  end

  def test_non_positive_input_error_with_default_message
    error = assert_raises(Calcpace::NonPositiveInputError) do
      @calc.check_positive(-1)
    end
    assert_includes error.message, 'must be a positive number'
  end

  def test_non_positive_input_error_with_custom_name
    error = assert_raises(Calcpace::NonPositiveInputError) do
      @calc.check_positive(0, 'Distance')
    end
    assert_includes error.message, 'Distance must be a positive number'
  end

  def test_invalid_time_format_error
    error = assert_raises(Calcpace::InvalidTimeFormatError) do
      @calc.check_time('invalid')
    end
    assert_includes error.message, 'XX:XX:XX or XX:XX'
  end

  def test_unsupported_unit_error
    error = assert_raises(Calcpace::UnsupportedUnitError) do
      @calc.constant(:invalid_unit)
    end
    assert_includes error.message, 'Unsupported unit'
  end

  def test_error_inheritance
    assert_kind_of StandardError, Calcpace::Error.new
    assert_kind_of Calcpace::Error, Calcpace::NonPositiveInputError.new
    assert_kind_of Calcpace::Error, Calcpace::InvalidTimeFormatError.new
    assert_kind_of Calcpace::Error, Calcpace::UnsupportedUnitError.new
  end
end
