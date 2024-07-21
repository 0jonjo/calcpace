# frozen_string_literal: true

require 'bigdecimal'

module Converter
  KM_TO_MI = BigDecimal('0.621371')
  MI_TO_KM = BigDecimal('1.60934')

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
    convert_the_distance(BigDecimal(distance.to_s), unit, round_limit)
  end

  def convert_to_seconds(time)
    hour, minute, seconds = time.split(':').map(&:to_i)
    (hour * 3600) + (minute * 60) + seconds
  end

  def convert_to_clocktime(seconds)
    format = seconds >= 86_400 ? '%d %H:%M:%S' : '%H:%M:%S'
    Time.at(seconds.to_i).utc.strftime(format)
  end

  def convert_the_distance(distance, unit, round_limit = 2)
    case unit
    when 'km'
      (distance * KM_TO_MI).round(round_limit)
    when 'mi'
      (distance * MI_TO_KM).round(round_limit)
    end
  end
end
