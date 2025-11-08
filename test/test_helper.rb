# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/pride'
require_relative '../lib/calcpace'

# Base test class with common setup
class CalcpaceTest < Minitest::Test
  def setup
    @calc = Calcpace.new
  end

  # Helper method to assert that a block raises a specific error with message
  def assert_error_with_message(error_class, expected_message = nil, &block)
    error = assert_raises(error_class, &block)
    assert_includes error.message, expected_message if expected_message
    error
  end

  # Helper method to assert float equality with tolerance
  def assert_in_delta_percent(expected, actual, percent = 0.01)
    delta = expected * percent
    assert_in_delta expected, actual, delta,
                    "Expected #{actual} to be within #{percent * 100}% of #{expected}"
  end
end
