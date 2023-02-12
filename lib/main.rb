require_relative 'run_convert'
require_relative 'run_check'

check_argv_length(ARGV)
check_digits_time(ARGV[1])
time_or_pace = convert_to_seconds((ARGV[1]))
distance_or_pace = ARGV[2]

case ARGV[0][0].downcase
when "p"
  check_digits_distance(distance_or_pace)
  pace = (time_or_pace / distance_or_pace.to_i)
  raise_negative(pace)
  puts convert_to_clocktime(pace)
when "t"
  check_digits_distance(distance_or_pace)
  time = (time_or_pace * distance_or_pace.to_i)
  raise_negative(time)
  puts convert_to_clocktime(time)
when "d"
  check_digits_time(distance_or_pace)
  distance = (time_or_pace.to_f) / convert_to_seconds(distance_or_pace)
  puts distance.round(2)
else
  raise ArgumentError, "You have to choose p (pace), t (time run) or d (distance)."  
end