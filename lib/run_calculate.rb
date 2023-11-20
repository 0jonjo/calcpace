# frozen_string_literal: true

def calculate(calc_modal, time_or_pace, distance_or_pace)
  case calc_modal
  when 'p'
    convert_to_clocktime((time_or_pace / distance_or_pace.to_i))
  when 't'
    convert_to_clocktime((time_or_pace * distance_or_pace.to_i))
  when 'd'
    (time_or_pace.to_f / convert_to_seconds(distance_or_pace)).round(2)
  end
end
