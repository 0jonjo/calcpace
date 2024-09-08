# frozen_string_literal: true

require 'bigdecimal'

# Module to calculate pace, time, distance and velocity
module Calculator
  def velocity(time, distance)
    time / distance
  end

  def checked_velocity(time, distance)
    check_time(time)
    check_positive(distance)
    distance_to_calc = convert_to_bigdecimal(distance)
    seconds = convert_to_bigdecimal(convert_to_seconds(time))
    velocity(seconds, distance_to_calc)
  end

  def clock_velocity(time, distance)
    velocity_in_seconds = checked_velocity(time, distance)
    convert_to_clocktime(velocity_in_seconds)
  end

  def time(velocity, distance)
    velocity * distance
  end

  def checked_time(pace, distance)
    check_time(pace)
    check_positive(distance)
    distance_to_calc = convert_to_bigdecimal(distance)
    pace_seconds = convert_to_bigdecimal(convert_to_seconds(pace))
    time(pace_seconds, distance_to_calc)
  end

  def clock_time(pace, distance)
    total_time_in_seconds = checked_time(pace, distance)
    convert_to_clocktime(total_time_in_seconds)
  end

  def distance(time, velocity)
    time / velocity
  end

  def checked_distance(time, velocity)
    check_time(time)
    check_time(velocity)
    time_seconds = convert_to_bigdecimal(convert_to_seconds(time))
    velocity_seconds = convert_to_bigdecimal(convert_to_seconds(velocity))
    distance(time_seconds, velocity_seconds)
  end
end
