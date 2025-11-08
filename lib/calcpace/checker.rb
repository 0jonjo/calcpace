# frozen_string_literal: true

require_relative 'errors'

# Module to validate input values and formats
#
# This module provides validation methods for numeric inputs and time format strings
# used throughout the Calcpace gem.
module Checker
  # Validates that a number is positive (greater than zero)
  #
  # @param number [Numeric] the number to validate
  # @param name [String] the name of the parameter for error messages
  # @raise [Calcpace::NonPositiveInputError] if number is not positive
  # @return [void]
  #
  # @example
  #   check_positive(10, 'Distance') #=> nil (valid)
  #   check_positive(-5, 'Time')     #=> raises NonPositiveInputError
  #   check_positive(0, 'Speed')     #=> raises NonPositiveInputError
  def check_positive(number, name = 'Input')
    return if number.is_a?(Numeric) && number.positive?

    raise Calcpace::NonPositiveInputError,
          "#{name} must be a positive number"
  end

  # Validates that a time string is in the correct format
  #
  # Accepted formats:
  # - HH:MM:SS (hours:minutes:seconds) - e.g., "01:30:45"
  # - MM:SS (minutes:seconds) - e.g., "05:30"
  # - H:MM:SS or M:SS (single digit hours/minutes) - e.g., "1:30:45"
  #
  # @param time_string [String] the time string to validate
  # @raise [Calcpace::InvalidTimeFormatError] if format is invalid
  # @return [void]
  #
  # @example
  #   check_time('01:30:45') #=> nil (valid)
  #   check_time('5:30')     #=> nil (valid)
  #   check_time('invalid')  #=> raises InvalidTimeFormatError
  def check_time(time_string)
    # Check if string is valid and matches expected patterns
    return if time_string.is_a?(String) &&
              (time_string =~ /\A\d{1,2}:\d{2}:\d{2}\z/ ||
               time_string =~ /\A\d{1,2}:\d{2}\z/)

    raise Calcpace::InvalidTimeFormatError,
          'It must be a valid time in the XX:XX:XX or XX:XX format'
  end
end
