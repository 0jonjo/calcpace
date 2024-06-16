# frozen_string_literal: true

module Converter
  def to_seconds(time)
    check_time(time)
    convert_to_seconds(time)
  end

  def to_clocktime(seconds)
    check_integer(seconds)
    convert_to_clocktime(seconds)
  end

  def convert(distance, unit, round_limit = 2)
    check_distance(distance)
    check_unit(unit)
    check_integer(round_limit)
    convert_the_distance(distance, unit, round_limit)
  end

  def convert_to_seconds(time)
    hour, minute, seconds = time.split(':').map(&:to_i)
    (hour * 3600) + (minute * 60) + seconds
  end

  def convert_to_clocktime(seconds)
    seconds >= 86_400 ? time = '%d %H:%M:%S' : time = '%H:%M:%S'
    Time.at(seconds).utc.strftime(time)
  end

  def convert_the_distance(distance, unit, round_limit = 2)
    case unit
    when 'km'
      (distance * 0.621371).round(round_limit)
    when 'mi'
      (distance * 1.60934).round(round_limit)
    end
  end
end
