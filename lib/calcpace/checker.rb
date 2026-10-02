# frozen_string_literal: true

require_relative 'errors'

# Module to validate input values and formats
#
# This module provides validation methods for numeric inputs and time format strings
# used throughout the Calcpace gem.
module Checker
  # Validates that a number is positive (greater than zero) and finite
  #
  # NaN and infinity are rejected too: NaN is not positive, and an infinite
  # distance or time would flow through the formulas into nonsense (a finite
  # "prediction") or a FloatDomainError far from the input that caused it.
  #
  # @param number [Numeric] the number to validate
  # @param name [String] the name of the parameter for error messages
  # @raise [Calcpace::NonPositiveInputError] if number is not positive or not finite
  # @return [void]
  #
  # @example
  #   check_positive(10, 'Distance')              #=> nil (valid)
  #   check_positive(-5, 'Time')                  #=> raises NonPositiveInputError
  #   check_positive(0, 'Speed')                  #=> raises NonPositiveInputError
  #   check_positive(Float::INFINITY, 'Distance') #=> raises NonPositiveInputError
  def check_positive(number, name = 'Input')
    unless number.is_a?(Numeric) && number.positive?
      raise Calcpace::NonPositiveInputError, "#{name} must be a positive number"
    end
    return if number.finite?

    raise Calcpace::NonPositiveInputError, "#{name} must be a finite positive number"
  end

  # Validates that a time string is a well-formed clock
  #
  # Accepted formats:
  # - H:MM:SS / HH:MM:SS (hours:minutes:seconds) - e.g., "1:30:45", "01:30:45"
  # - M:SS / MM:SS (minutes:seconds) - e.g., "5:30", "05:30"
  #
  # Seconds must be below 60 in both formats, and so must minutes once an
  # hour field is present ("1:60:00" is not a clock). MM:SS keeps counting
  # minutes past the hour, as the padded paces from track_splits do: "75:00"
  # is a valid 75-minute time.
  #
  # @param time_string [String] the time string to validate
  # @raise [Calcpace::InvalidTimeFormatError] if format is invalid
  # @return [void]
  #
  # @example
  #   check_time('01:30:45') #=> nil (valid)
  #   check_time('5:30')     #=> nil (valid)
  #   check_time('75:00')    #=> nil (valid, 75 minutes)
  #   check_time('05:99')    #=> raises InvalidTimeFormatError
  #   check_time('1:60:00')  #=> raises InvalidTimeFormatError
  #   check_time('invalid')  #=> raises InvalidTimeFormatError
  def check_time(time_string)
    return if time_string.is_a?(String) &&
              (time_string.match?(/\A\d{1,2}:[0-5]\d:[0-5]\d\z/) ||
               time_string.match?(/\A\d{1,2}:[0-5]\d\z/))

    raise Calcpace::InvalidTimeFormatError,
          'It must be a valid time in the XX:XX:XX or XX:XX format ' \
          '(seconds below 60, and minutes too when hours are given)'
  end
end
