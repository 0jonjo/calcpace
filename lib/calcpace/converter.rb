# frozen_string_literal: true

require 'bigdecimal'

# Module to convert units
module Converter
  KM_TO_MI = 0.621371
  MI_TO_KM = 1.60934
  NAUTICAL_MI_TO_KM = 1.852
  KM_TO_NAUTICAL_MI = 0.539957
  METERS_TO_KM = 0.001
  KM_TO_METERS = 1000
  METERS_TO_MI = 0.000621371
  MI_TO_METERS = 1609.34
  METERS_TO_FEET = 3.28084
  FEET_TO_METERS = 0.3048
  METERS_TO_YARDS = 1.09361
  YARDS_TO_METERS = 0.9144
  METERS_TO_INCHES = 39.3701
  INCHES_TO_METERS = 0.0254

  M_S_TO_KM_H = 3.6
  KM_H_TO_M_S = 0.277778
  M_S_TO_MI_H = 2.23694
  MI_H_TO_M_S = 0.44704
  M_S_TO_NAUTICAL_MI_H = 1.94384
  NAUTICAL_MI_H_TO_M_S = 0.514444
  M_S_TO_FEET_S = 3.28084
  FEET_S_TO_M_S = 0.3048
  M_S_TO_KNOTS = 1.94384
  KNOTS_TO_M_S = 0.514444
  KM_H_TO_MI_H = 0.621371
  MI_H_TO_KM_H = 1.60934

  def convert(value, unit)
    check_positive(value)
    unit_constant = constant(unit)
    value_to_convert = convert_to_bigdecimal(value)
    unit_to_convert = convert_to_bigdecimal(unit_constant)
    value_to_convert * unit_to_convert
  end

  def convert_to_seconds(time)
    hour, minute, seconds = time.split(':').map(&:to_i)
    (hour * 3600) + (minute * 60) + seconds
  end

  def convert_to_clocktime(seconds)
    format = seconds >= 86_400 ? '%d %H:%M:%S' : '%H:%M:%S'
    Time.at(seconds.to_i).utc.strftime(format)
  end

  def convert_to_bigdecimal(value)
    bigdecimal ? BigDecimal(value.to_s) : value
  end

  def constant(string)
    Converter.const_get(string.upcase.gsub(' ', '_'))
  end

  def list_constants
    Converter.constants
  end
end
