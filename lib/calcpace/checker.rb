# frozen_string_literal: true

require_relative 'errors'

# Module to check if the input is valid or of the correct type
module Checker
  def check_positive(number, name = 'Input')
    return if number.is_a?(Numeric) && number.positive?

    raise Calcpace::NonPositiveInputError,
          "#{name} must be a positive number"
  end

  def check_time(time_string)
    return if time_string =~ /\A\d{1,2}:\d{2}:\d{2}\z/ ||
              time_string =~ /\A\d{1,2}:\d{2}\z/

    raise Calcpace::InvalidTimeFormatError, 'It must be a valid time in the XX:XX:XX or XX:XX format'
  end
end
