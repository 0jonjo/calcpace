# frozen_string_literal: true

require 'bigdecimal'

module Calculator
  def pace(time, distance, bigdecimal = false)
    pace_in_seconds = pace_seconds(time, distance, bigdecimal)
    convert_to_clocktime(pace_in_seconds)
  end

  def pace_seconds(time, distance, bigdecimal = false)
    check_time(time)
    check_distance(distance)
    seconds = convert_to_seconds(time)
    bigdecimal ? seconds / BigDecimal(distance.to_s) : seconds / distance
  end

  def total_time(pace, distance, bigdecimal = false)
    total_time_in_seconds = total_time_seconds(pace, distance, bigdecimal)
    convert_to_clocktime(total_time_in_seconds)
  end

  def total_time_seconds(pace, distance, bigdecimal = false)
    check_time(pace)
    check_distance(distance)
    pace_seconds = convert_to_seconds(pace)
    bigdecimal ? pace_seconds * BigDecimal(distance.to_s) : pace_seconds * distance
  end

  def distance(time, pace, bigdecimal = false)
    check_time(time)
    check_time(pace)
    if bigdecimal
      time_seconds = BigDecimal(convert_to_seconds(time).to_s)
      pace_seconds = BigDecimal(convert_to_seconds(pace).to_s)
    else
      time_seconds = convert_to_seconds(time)
      pace_seconds = convert_to_seconds(pace)
    end
    time_seconds / pace_seconds
  end
end
