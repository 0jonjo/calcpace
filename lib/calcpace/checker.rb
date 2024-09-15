# frozen_string_literal: true

# Module to check if the input is valid or of the correct type
module Checker
  def check_positive(number)
    raise 'It must be a X.X positive number' unless number.positive?
  end

  def check_time(time_string)
    raise 'It must be a XX:XX:XX time' unless time_string =~ /\d{0,2}(:)*?\d{1,2}(:)\d{1,2}/
  end
end
