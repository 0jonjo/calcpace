# frozen_string_literal: true

# Module to convert units
module Converter
  module Distance
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
    KM_TO_YARDS = 1093.61
    YARDS_TO_KM = 0.0009144
    KM_TO_FEET = 3280.84
    FEET_TO_KM = 0.0003048
    KM_TO_INCHES = 39_370.1
    INCHES_TO_KM = 0.0000254
    MI_TO_YARDS = 1760
    YARDS_TO_MI = 0.000568182
    MI_TO_FEET = 5280
    FEET_TO_MI = 0.000189394
    MI_TO_INCHES = 63_360
    INCHES_TO_MI = 0.0000157828
  end

  module Speed
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
    KM_H_TO_NAUTICAL_MI_H = 0.539957
    NAUTICAL_MI_H_TO_KM_H = 1.852
    MI_H_TO_NAUTICAL_MI_H = 0.868976
    NAUTICAL_MI_H_TO_MI_H = 1.15078
  end

  def convert(value, unit)
    check_positive(value)
    unit_constant = constant(unit)
    value * unit_constant
  end

  def convert_to_seconds(time)
    hour, minute, seconds = time.split(':').map(&:to_i)
    (hour * 3600) + (minute * 60) + seconds
  end

  def convert_to_clocktime(seconds)
    format = seconds >= 86_400 ? '%d %H:%M:%S' : '%H:%M:%S'
    Time.at(seconds.to_i).utc.strftime(format)
  end

  def constant(symbol)
    Distance.const_get(symbol.to_s.upcase)
  rescue NameError
    Speed.const_get(symbol.to_s.upcase)
  end

  def list_all
    (Distance.constants + Speed.constants).map { |c| c.downcase.to_sym }
  end

  def list_speed
    Speed.constants.map { |c| c.downcase.to_sym }
  end

  def list_distance
    Distance.constants.map { |c| c.downcase.to_sym }
  end
end
