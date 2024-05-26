# frozen_string_literal: true

module Converter
  def convert_to_seconds(time)
    hour, minute, seconds = time.split(':').map(&:to_i)
    (hour * 3600) + (minute * 60) + seconds
  end

  def convert_to_clocktime(seconds)
    Time.at(seconds).utc.strftime('%H:%M:%S')
  end

  # tem que chamar as checagens de digitos antes de chamar o convert_distance
  def convert(distance, unit)
    case unit
    when 'km'
      (distance * 0.621371).round(2)
    when 'mi'
      (distance * 1.60934).round(2)
    end
  end
end
