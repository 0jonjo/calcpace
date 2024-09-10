# frozen_string_literal: true

require 'bigdecimal'

# Module to calculate time, distance, pace and velocity
# Convert distance in float to obtain
module Calculator
  def velocity(time, distance)
    distance_to_calc = bigdecimal ? distance : distance.to_f
    distance_to_calc / time
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

  def pace(time, distance)
    distance_to_calc = bigdecimal ? distance : distance.to_f
    time / distance_to_calc
  end

  def checked_pace(time, distance)
    check_time(time)
    check_positive(distance)
    distance_to_calc = convert_to_bigdecimal(distance)
    seconds = convert_to_bigdecimal(convert_to_seconds(time))
    pace(seconds, distance_to_calc)
  end

  def clock_pace(time, distance)
    velocity_in_seconds = checked_pace(time, distance)
    convert_to_clocktime(velocity_in_seconds)
  end

  def time(velocity, distance)
    distance_to_calc = bigdecimal ? distance : distance.to_f
    velocity * distance_to_calc
  end

  def checked_time(velocity, distance)
    check_time(velocity)
    check_positive(distance)
    distance_to_calc = convert_to_bigdecimal(distance)
    velocity_seconds = convert_to_bigdecimal(convert_to_seconds(velocity))
    time(velocity_seconds, distance_to_calc)
  end

  def clock_time(velocity, distance)
    total_time_in_seconds = checked_time(velocity, distance)
    convert_to_clocktime(total_time_in_seconds)
  end

  def distance(time, velocity)
    time_to_calc = bigdecimal ? time : time.to_f
    time_to_calc / velocity
  end

  def checked_distance(time, velocity)
    check_time(time)
    check_time(velocity)
    time_seconds = convert_to_bigdecimal(convert_to_seconds(time))
    velocity_seconds = convert_to_bigdecimal(convert_to_seconds(velocity))
    distance(time_seconds, velocity_seconds)
  end
end
