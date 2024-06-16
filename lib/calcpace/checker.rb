# frozen_string_literal: true

module Checker
  def check_distance(distance)
    raise 'It must be a X.X positive number' unless distance.positive?
  end

  def check_time(time_string)
    raise 'It must be a XX:XX:XX time' unless time_string =~ /\d{0,2}(:)*?\d{1,2}(:)\d{1,2}/
  end

  def check_second(second)
    raise 'It must be a positive number' unless second.is_a?(Integer) && second.positive?
  end

  def check_unit(unit)
    raise 'It must be km or mi' unless %w[km mi].include?(unit)
  end
end
