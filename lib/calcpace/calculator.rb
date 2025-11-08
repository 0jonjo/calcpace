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

  def checked_velocity(time, distance)
    seconds = convert_to_seconds(validate_time(time))
    velocity(seconds, distance)
  end

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

  def checked_pace(time, distance)
    seconds = convert_to_seconds(validate_time(time))
    pace(seconds, distance)
  end

  def clock_pace(time, distance)
    convert_to_clocktime(checked_pace(time, distance))
  end

  def time(velocity, distance)
    validate_positive({ velocity: velocity, distance: distance })
    velocity * distance
  end

  def checked_time(velocity, distance)
    velocity_seconds = convert_to_seconds(validate_time(velocity))
    time(velocity_seconds, distance)
  end

  def clock_time(velocity, distance)
    convert_to_clocktime(checked_time(velocity, distance))
  end

  def distance(time, velocity)
    validate_positive({ time: time, velocity: velocity })
    time.to_f / velocity
  end

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
