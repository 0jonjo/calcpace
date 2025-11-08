# frozen_string_literal: true

# Module to convert between different units of distance and speed
#
# This module provides conversion methods for 42 different unit pairs,
# including distance units (kilometers, miles, meters, feet, etc.) and
# speed units (m/s, km/h, mi/h, knots, etc.).
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

  # Converts a value from one unit to another
  #
  # @param value [Numeric] the value to convert
  # @param unit [Symbol, String] the conversion unit (e.g., :km_to_mi or 'km to mi')
  # @return [Float] the converted value
  # @raise [Calcpace::NonPositiveInputError] if value is not positive
  # @raise [Calcpace::UnsupportedUnitError] if the unit is not supported
  #
  # @example
  #   convert(10, :km_to_mi)    #=> 6.21371 (10 km = 6.21 miles)
  #   convert(5, 'mi to km')    #=> 8.0467 (5 miles = 8.05 km)
  def convert(value, unit)
    check_positive(value, 'Value')
    unit_constant = constant(unit)
    value * unit_constant
  end

  # Converts a time string to total seconds
  #
  # @param time [String] time string in HH:MM:SS or MM:SS format
  # @return [Integer] total seconds
  #
  # @example
  #   convert_to_seconds('01:30:00') #=> 5400 (1 hour 30 minutes)
  #   convert_to_seconds('05:30')    #=> 330 (5 minutes 30 seconds)
  def convert_to_seconds(time)
    parts = time.split(':').map(&:to_i)
    case parts.length
    when 2
      minute, seconds = parts
      (minute * 60) + seconds
    when 3
      hour, minute, seconds = parts
      (hour * 3600) + (minute * 60) + seconds
    else
      0
    end
  end

  # Converts seconds to a clocktime string
  #
  # @param seconds [Numeric] total seconds
  # @return [String] time in HH:MM:SS format, or "D HH:MM:SS" for durations over 24 hours
  #
  # @example
  #   convert_to_clocktime(3600)    #=> '01:00:00' (1 hour)
  #   convert_to_clocktime(100000)  #=> '1 03:46:40' (1 day, 3 hours, 46 minutes, 40 seconds)
  def convert_to_clocktime(seconds)
    days = seconds / 86_400
    format = days.to_i.positive? ? "#{days} %H:%M:%S" : '%H:%M:%S'
    Time.at(seconds).utc.strftime(format)
  end

  # Retrieves the conversion constant for a given unit
  #
  # @param unit [Symbol, String] the unit conversion (e.g., :km_to_mi or 'km to mi')
  # @return [Float] the conversion factor
  # @raise [Calcpace::UnsupportedUnitError] if the unit is not supported
  #
  # @example
  #   constant(:km_to_mi)    #=> 0.621371
  #   constant('km to mi')   #=> 0.621371
  def constant(unit)
    unit = format_unit(unit) if unit.is_a?(String)
    Distance.const_get(unit.to_s.upcase)
  rescue NameError
    begin
      Speed.const_get(unit.to_s.upcase)
    rescue NameError
      raise Calcpace::UnsupportedUnitError, unit
    end
  end

  def list_all
    format_list(Distance.constants + Speed.constants)
  end

  def list_speed
    format_list(Speed.constants)
  end

  def list_distance
    format_list(Distance.constants)
  end

  private

  def format_unit(unit)
    unit.downcase.gsub(' ', '_').to_sym
  end

  def format_list(constants)
    constants.to_h { |c| [c.downcase.to_sym, c.to_s.gsub('_', ' ').gsub(' TO ', ' to ')] }
  end
end
