# frozen_string_literal: true

def calculate(calc_modal, time_or_pace, distance_or_pace)
  case calc_modal
  when 'p'
    convert_to_clocktime(convert_to_seconds(time_or_pace) / distance_or_pace.to_f)
  when 't'
    convert_to_clocktime(convert_to_seconds(time_or_pace) * distance_or_pace.to_f)
  when 'd'
    convert_to_seconds(time_or_pace).to_f / convert_to_seconds(distance_or_pace).round(2)
  when 'c'
    convert_distance(time_or_pace, distance_or_pace.to_f).round(2)
  end
end

def convert_distance(unit, distance)
  case unit
  when 'km'
    (distance * 0.621371)
  when 'mi'
    (distance * 1.60934)
  end
end

