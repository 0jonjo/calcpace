# frozen_string_literal: true

# Module to check if the input is valid or of the correct type
module Checker
  def check_positive(number)
    raise ArgumentError, 'It must be a positive number' unless number.is_a?(Numeric) && number.positive?
  end

  def check_time(time_string)
    return if time_string =~ /\A\d{1,2}:\d{2}:\d{2}\z/

    raise ArgumentError,
          'It must be a valid time in the format XX:XX:XX'
  end
end
