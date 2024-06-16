# frozen_string_literal: true

module Calculator
  def pace(time, distance)
    check_time(time)
    check_distance(distance)
    convert_to_clocktime(convert_to_seconds(time) / distance.to_f)
  end

  def total_time(pace, distance)
    check_time(pace)
    check_distance(distance)
    convert_to_clocktime(convert_to_seconds(pace) * distance.to_f)
  end

  def distance(time, pace)
    check_time(time)
    check_time(pace)
    convert_to_seconds(time).to_f / convert_to_seconds(pace).round(2)
  end

  def convert_distance(distance, unit)
    check_distance(distance)
    check_unit(unit)
    convert_the_distance(distance, unit)
  end
end
