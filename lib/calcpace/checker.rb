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
  # "prediction") or a FloatDomainError far from the input that caused it. So
  # is an Integer too large for a Float (a clock with hundreds of hour digits
  # parses to one), which would turn into Infinity inside the formulas.
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
    # An Integer is always finite, but one past Float::MAX overflows to
    # Infinity the moment a formula calls to_f on it
    return if number.finite? && number.to_f.finite?

    raise Calcpace::NonPositiveInputError, "#{name} must be a finite positive number"
  end

  # The clock grammar every time and pace string in the gem is read with. It
  # covers every clock the gem writes (and a few it never writes, such as
  # '-1 03:46:40' or '000000000:00'):
  # - an optional leading '-' (track_splits reports a backwards split as '-0:40')
  # - an optional day prefix, 'D HH:MM:SS', as convert_to_clocktime writes
  #   durations above 24 hours ('1 03:46:40'); the hour field after it is two
  #   digits below 24
  # - H:MM:SS, where the hours have any number of digits ('400:00:00') and the
  #   minutes and seconds are two digits below 60
  # - M:SS, where the minutes have any number of digits and keep counting past
  #   the hour ('75:00', '123:45') and the seconds are two digits below 60
  # Nothing else: no '+', no blanks or surrounding whitespace, ASCII digits only,
  # and only in a String whose encoding is valid and ASCII-compatible.
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
    match = CLOCK_FORMAT.match(time_string) if clock_encoding?(time_string)
    return match if match

    raise Calcpace::InvalidTimeFormatError,
          'It must be a valid time in the XX:XX:XX or XX:XX format ' \
          '(seconds below 60, and minutes too when hours are given)'
  end

  # Only a String in a valid, ASCII-compatible encoding can be a clock: the
  # pattern cannot match UTF-16/UTF-32, and a broken byte sequence raises
  # ArgumentError inside the regexp engine instead of a clock error
  def clock_encoding?(time_string)
    time_string.is_a?(String) && time_string.valid_encoding? && time_string.encoding.ascii_compatible?
  end

  # Age in whole years, 18 or over — the rule AgeGrading and Vo2maxNorms share
  #
  # @raise [ArgumentError] if age is not an integer or is under 18
  def normalize_age(age)
    age_value = Integer(age)
  rescue ArgumentError, TypeError
    raise ArgumentError, 'Age must be an integer greater than or equal to 18'
  else
    raise ArgumentError, 'Age must be at least 18' if age_value < 18

    age_value
  end

  # :male or :female, from any case of a String or Symbol — shared like normalize_age
  #
  # @raise [ArgumentError] for anything else
  def normalize_sex(sex)
    normalized = sex.to_s.strip.downcase.to_sym
    return normalized if %i[male female].include?(normalized)

    raise ArgumentError, "Sex must be 'male' or 'female'"
  end
end
