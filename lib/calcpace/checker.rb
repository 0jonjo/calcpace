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

  # The clock grammar every time and pace string in the gem is read with —
  # exactly the clocks the gem itself writes:
  # - an optional leading '-' (track_splits reports a backwards split as '-0:40')
  # - an optional day prefix, 'D HH:MM:SS', as convert_to_clocktime writes
  #   durations above 24 hours ('1 03:46:40'); the hour field after it is two
  #   digits below 24
  # - H:MM:SS, where the hours have any number of digits ('400:00:00') and the
  #   minutes and seconds are two digits below 60
  # - M:SS, where the minutes have any number of digits and keep counting past
  #   the hour ('75:00', '123:45') and the seconds are two digits below 60
  # Nothing else: no '+', no blanks or surrounding whitespace, ASCII digits only.
  CLOCK_FORMAT = /
    \A(?<sign>-)?
    (?:(?<days>\d+)[ ](?=(?:[01]\d|2[0-3]):[0-5]\d:))?
    (?:(?<hours>\d+):(?<minutes>[0-5]\d)|(?<total_minutes>\d+))
    :(?<seconds>[0-5]\d)\z
  /x

  # Validates that a time string is a well-formed clock
  #
  # Accepts what CLOCK_FORMAT describes, i.e. every clock the gem formats:
  # H:MM:SS / HH:MM:SS with any number of hour digits, M:SS / MM:SS with any
  # number of minute digits, the 'D HH:MM:SS' day prefix of convert_to_clocktime
  # and an optional leading '-'. Seconds must be below 60, and so must minutes
  # once an hour field is present ("1:60:00" is not a clock); MM:SS keeps
  # counting minutes past the hour, so "75:00" is a valid 75-minute time.
  #
  # A negative clock is well formed (track_splits writes one for a backwards
  # split); methods that need a positive time or pace reject it with
  # Calcpace::NonPositiveInputError after parsing.
  #
  # @param time_string [String] the time string to validate
  # @raise [Calcpace::InvalidTimeFormatError] if format is invalid
  # @return [void]
  #
  # @example
  #   check_time('01:30:45')   #=> nil (valid)
  #   check_time('5:30')       #=> nil (valid)
  #   check_time('75:00')      #=> nil (valid, 75 minutes)
  #   check_time('1 03:46:40') #=> nil (valid, 1 day 3:46:40)
  #   check_time('-0:40')      #=> nil (valid, a backwards split)
  #   check_time('05:99')      #=> raises InvalidTimeFormatError
  #   check_time('1:60:00')    #=> raises InvalidTimeFormatError
  #   check_time('invalid')    #=> raises InvalidTimeFormatError
  def check_time(time_string)
    clock_match(time_string)
    nil
  end

  private

  # @return [MatchData] the CLOCK_FORMAT match for a valid clock
  # @raise [Calcpace::InvalidTimeFormatError] otherwise
  def clock_match(time_string)
    match = CLOCK_FORMAT.match(time_string) if time_string.is_a?(String)
    return match if match

    raise Calcpace::InvalidTimeFormatError,
          'It must be a valid time in the XX:XX:XX or XX:XX format ' \
          '(seconds below 60, and minutes too when hours are given)'
  end
end
