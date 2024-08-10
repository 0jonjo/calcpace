# frozen_string_literal: true

require 'bigdecimal'

module Converter
  KM_TO_MI_BIGDECIMAL = BigDecimal('0.621371')
  KM_TO_MI = 0.621371
  MI_TO_KM_BIGDECIMAL = BigDecimal('1.60934')
  MI_TO_KM = 1.60934

  def to_seconds(time)
    check_time(time)
    convert_to_seconds(time)
  end

  def to_clocktime(seconds)
    check_integer(seconds)
    convert_to_clocktime(seconds)
  end

  def convert(distance, unit)
    check_distance(distance)
    check_unit(unit)
    bigdecimal ? distance_to_convert = BigDecimal(distance.to_s) : distance_to_convert = distance
    convert_the_distance(distance_to_convert, unit)
  end

  def convert_to_seconds(time)
    hour, minute, seconds = time.split(':').map(&:to_i)
    (hour * 3600) + (minute * 60) + seconds
  end

  def convert_to_clocktime(seconds)
    format = seconds >= 86_400 ? '%d %H:%M:%S' : '%H:%M:%S'
    Time.at(seconds.to_i).utc.strftime(format)
  end

  def convert_the_distance(distance, unit)
    case unit
    when 'km'
      bigdecimal ? km_to_mi = KM_TO_MI_BIGDECIMAL : km_to_mi = KM_TO_MI
      (distance * km_to_mi)
    when 'mi'
      bigdecimal ? mi_to_km = MI_TO_KM_BIGDECIMAL : mi_to_km = MI_TO_KM
      (distance * mi_to_km)
    end
  end
end
