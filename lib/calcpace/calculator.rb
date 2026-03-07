# frozen_string_literal: true

# Module to calculate time, distance, pace and velocity
#
# This module provides methods to perform calculations related to running and pace.
# All methods that accept numeric inputs validate that values are positive.
# Methods prefixed with 'checked_' accept time strings in HH:MM:SS or MM:SS format.
# Methods prefixed with 'clock_' return results in time format (HH:MM:SS).
module Calculator
  # Calculates velocity (distance per unit time)
  #
  # @param time [Numeric] time in any unit (e.g., seconds, hours)
  # @param distance [Numeric] distance in any unit (e.g., meters, kilometers)
  # @return [Float] velocity (distance/time)
  # @raise [Calcpace::NonPositiveInputError] if time or distance is not positive
  #
  # @example
  #   velocity(3600, 12000) #=> 3.333... (12000 meters / 3600 seconds = 3.33 m/s)
  def velocity(time, distance)
    validate_positive({ time: time, distance: distance })
    distance.to_f / time
  end

  # Calculates velocity from a time string
  #
  # @param time [String] time in HH:MM:SS or MM:SS format
  # @param distance [Numeric] distance in any unit (e.g., meters, kilometers)
  # @return [Float] velocity (distance/time)
  # @raise [Calcpace::InvalidTimeFormatError] if time string is invalid
  # @raise [Calcpace::NonPositiveInputError] if distance is not positive
  #
  # @example
  #   checked_velocity('01:00:00', 10_000) #=> 2.778 (10000 meters / 3600 seconds)
  def checked_velocity(time, distance)
    seconds = convert_to_seconds(validate_time(time))
    velocity(seconds, distance)
  end

  # Calculates velocity from a time string and returns result as a clock time string
  #
  # @param time [String] time in HH:MM:SS or MM:SS format
  # @param distance [Numeric] distance in any unit
  # @return [String] velocity in HH:MM:SS format
  # @raise [Calcpace::InvalidTimeFormatError] if time string is invalid
  # @raise [Calcpace::NonPositiveInputError] if distance is not positive
  #
  # @example
  #   clock_velocity('01:00:00', 10_000) #=> '00:00:00'
  def clock_velocity(time, distance)
    convert_to_clocktime(checked_velocity(time, distance))
  end

  # Calculates pace (time per unit distance)
  #
  # @param time [Numeric] time in any unit (e.g., seconds, minutes)
  # @param distance [Numeric] distance in any unit (e.g., kilometers, miles)
  # @return [Float] pace (time/distance)
  # @raise [Calcpace::NonPositiveInputError] if time or distance is not positive
  #
  # @example
  #   pace(3600, 12) #=> 300.0 (3600 seconds / 12 km = 300 seconds/km = 5:00/km)
  def pace(time, distance)
    validate_positive({ time: time, distance: distance })
    time.to_f / distance
  end

  # Calculates pace from a time string
  #
  # @param time [String] time in HH:MM:SS or MM:SS format
  # @param distance [Numeric] distance in any unit (e.g., kilometers, miles)
  # @return [Float] pace (time/distance) in seconds
  # @raise [Calcpace::InvalidTimeFormatError] if time string is invalid
  # @raise [Calcpace::NonPositiveInputError] if distance is not positive
  #
  # @example
  #   checked_pace('00:50:00', 10) #=> 300.0 (300 seconds/km = 5:00/km)
  def checked_pace(time, distance)
    seconds = convert_to_seconds(validate_time(time))
    pace(seconds, distance)
  end

  # Calculates pace from a time string and returns result as a clock time string
  #
  # @param time [String] time in HH:MM:SS or MM:SS format
  # @param distance [Numeric] distance in any unit
  # @return [String] pace in HH:MM:SS format
  # @raise [Calcpace::InvalidTimeFormatError] if time string is invalid
  # @raise [Calcpace::NonPositiveInputError] if distance is not positive
  #
  # @example
  #   clock_pace('00:50:00', 10) #=> '00:05:00'
  def clock_pace(time, distance)
    convert_to_clocktime(checked_pace(time, distance))
  end

  # Calculates time given velocity and distance
  #
  # @param velocity [Numeric] velocity in any unit
  # @param distance [Numeric] distance in any unit
  # @return [Float] time (velocity * distance)
  # @raise [Calcpace::NonPositiveInputError] if velocity or distance is not positive
  #
  # @example
  #   time(300, 10) #=> 3000.0 (300 s/km * 10 km = 3000 seconds)
  def time(velocity, distance)
    validate_positive({ velocity: velocity, distance: distance })
    velocity * distance
  end

  # Calculates time from a velocity string and distance
  #
  # @param velocity [String] velocity in HH:MM:SS or MM:SS format
  # @param distance [Numeric] distance in any unit
  # @return [Float] time in seconds
  # @raise [Calcpace::InvalidTimeFormatError] if velocity string is invalid
  # @raise [Calcpace::NonPositiveInputError] if distance is not positive
  #
  # @example
  #   checked_time('05:00', 10) #=> 3000.0 (5:00/km * 10 km = 3000 seconds)
  def checked_time(velocity, distance)
    velocity_seconds = convert_to_seconds(validate_time(velocity))
    time(velocity_seconds, distance)
  end

  # Calculates time from a velocity string and returns result as a clock time string
  #
  # @param velocity [String] velocity in HH:MM:SS or MM:SS format
  # @param distance [Numeric] distance in any unit
  # @return [String] time in HH:MM:SS format
  # @raise [Calcpace::InvalidTimeFormatError] if velocity string is invalid
  # @raise [Calcpace::NonPositiveInputError] if distance is not positive
  #
  # @example
  #   clock_time('05:00', 10) #=> '00:50:00'
  def clock_time(velocity, distance)
    convert_to_clocktime(checked_time(velocity, distance))
  end

  # Calculates distance given time and velocity
  #
  # @param time [Numeric] time in any unit
  # @param velocity [Numeric] velocity in any unit
  # @return [Float] distance (time/velocity)
  # @raise [Calcpace::NonPositiveInputError] if time or velocity is not positive
  #
  # @example
  #   distance(3000, 300) #=> 10.0 (3000 seconds / 300 s/km = 10 km)
  def distance(time, velocity)
    validate_positive({ time: time, velocity: velocity })
    time.to_f / velocity
  end

  # Calculates distance from time and velocity strings
  #
  # @param time [String] time in HH:MM:SS or MM:SS format
  # @param velocity [String] velocity in HH:MM:SS or MM:SS format
  # @return [Float] distance
  # @raise [Calcpace::InvalidTimeFormatError] if any string is invalid
  #
  # @example
  #   checked_distance('00:50:00', '05:00') #=> 10.0 (50 min / 5:00/km = 10 km)
  def checked_distance(time, velocity)
    time_seconds = convert_to_seconds(validate_time(time))
    velocity_seconds = convert_to_seconds(validate_time(velocity))
    distance(time_seconds, velocity_seconds)
  end

  private

  def validate_positive(values)
    values.each { |name, value| check_positive(value, name.capitalize) }
  end

  def validate_time(time)
    check_time(time)
    time
  end
end
