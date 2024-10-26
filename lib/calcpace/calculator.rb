# frozen_string_literal: true

# Module to calculate time, distance, pace and velocity
module Calculator
  def velocity(time, distance)
    validate_positive(time, distance)
    distance.to_f / time
  end

  def checked_velocity(time, distance)
    seconds = convert_to_seconds(validate_time(time))
    velocity(seconds, distance)
  end

  def clock_velocity(time, distance)
    convert_to_clocktime(checked_velocity(time, distance))
  end

  def pace(time, distance)
    validate_positive(time, distance)
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
    validate_positive(velocity, distance)
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
    validate_positive(time, velocity)
    time.to_f / velocity
  end

  def checked_distance(time, velocity)
    time_seconds = convert_to_seconds(validate_time(time))
    velocity_seconds = convert_to_seconds(validate_time(velocity))
    distance(time_seconds, velocity_seconds)
  end

  private

  def validate_positive(*values)
    values.each { |value| check_positive(value) }
  end

  def validate_time(time)
    check_time(time)
    time
  end
end
