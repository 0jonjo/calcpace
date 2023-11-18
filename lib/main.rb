# frozen_string_literal: true

require_relative 'run_convert'
require_relative 'run_check'

check_argv_length(ARGV)
check_digits_time(ARGV[1])
time_or_pace = convert_to_seconds((ARGV[1]))
distance_or_pace = ARGV[2]
check_digits_distance(distance_or_pace)

case ARGV[0][0].downcase
when 'p'
  time_to_calculate = (time_or_pace / distance_or_pace.to_i)
when 't'
  time_to_calculate = (time_or_pace * distance_or_pace.to_i)
when 'd'
  distance = time_or_pace.to_f / convert_to_seconds(distance_or_pace)
else
  raise ArgumentError, 'You have to choose p (pace), t (time run) or d (distance).'
end

puts convert_to_clocktime(raise_negative(time_or_pace)) if time_to_calculate
puts distance.round(2) if distance
