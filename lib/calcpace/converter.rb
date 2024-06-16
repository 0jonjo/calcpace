# frozen_string_literal: true

module Converter
  def to_seconds(time)
    check_time(time)
    convert_to_seconds(time)
  end

  def to_clocktime(seconds)
    check_second(seconds)
    convert_to_clocktime(seconds)
  end

  def convert(distance, unit)
    check_distance(distance)
    check_unit(unit)
    convert_distance(distance, unit)
  end

  def convert_to_seconds(time)
    hour, minute, seconds = time.split(':').map(&:to_i)
    (hour * 3600) + (minute * 60) + seconds
  end

  def convert_to_clocktime(seconds)
    Time.at(seconds).utc.strftime('%H:%M:%S')
  end

  def convert_the_distance(distance, unit)
    case unit
    when 'km'
      (distance * 0.621371).round(2)
    when 'mi'
      (distance * 1.60934).round(2)
    end
  end
end
