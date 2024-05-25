# frozen_string_literal: true

module Checker
  def check_digits(time, distance)
    check_digits_time(time)
    check_digits_distance(distance)
  end

  def check_digits_distance(distance)
    raise 'It must be a X.X positive number' unless distance.positive?
  end

  def check_digits_time(time_string)
    raise 'It must be a XX:XX:XX time' unless time_string =~ /\d{0,2}(:)*?\d{1,2}(:)\d{1,2}/
  end

  def check_unit(unit)
    raise 'It must be km or mi' unless ['km', 'mi'].include?(unit)
  end
end
