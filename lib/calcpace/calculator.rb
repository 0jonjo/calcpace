# frozen_string_literal: true

# Module to calculate time, distance, pace and velocity
module Calculator
  def velocity(time, distance)
    check_positive(distance)
    check_positive(time)
    distance.to_f / time
  end

  def checked_velocity(time, distance)
    check_time(time)
    seconds = convert_to_seconds(time)
    velocity(seconds, distance)
  end

  def clock_velocity(time, distance)
    velocity_in_seconds = checked_velocity(time, distance)
    convert_to_clocktime(velocity_in_seconds)
  end

  def pace(time, distance)
    check_positive(distance)
    check_positive(time)
    time.to_f / distance
  end

  def checked_pace(time, distance)
    check_time(time)
    seconds = convert_to_seconds(time)
    pace(seconds, distance)
  end

  def clock_pace(time, distance)
    velocity_in_seconds = checked_pace(time, distance)
    convert_to_clocktime(velocity_in_seconds)
  end

  def time(velocity, distance)
    check_positive(distance)
    check_positive(velocity)
    velocity * distance
  end

  def checked_time(velocity, distance)
    check_time(velocity)
    velocity_seconds = convert_to_seconds(velocity)
    time(velocity_seconds, distance)
  end

  def clock_time(velocity, distance)
    total_time_in_seconds = checked_time(velocity, distance)
    convert_to_clocktime(total_time_in_seconds)
  end

  def distance(time, velocity)
    check_positive(time)
    check_positive(velocity)
    time.to_f / velocity
  end

  def checked_distance(time, velocity)
    check_time(time)
    check_time(velocity)
    time_seconds = convert_to_seconds(time)
    velocity_seconds = convert_to_seconds(velocity)
    distance(time_seconds, velocity_seconds)
  end
end
