require_relative 'run_calc'
require_relative 'run_convert'
require_relative 'run_check'

check_argv_length(ARGV)

case ARGV[0][0].downcase
when "p"
  run_time = convert_to_seconds(check_digits_time(ARGV[1]))
  run_distance = check_digits_distance(ARGV[2])
  run_pace = calculate_pace(run_time, run_distance).to_i
  raise_negative(run_pace)
  puts convert_to_clocktime(run_pace)
when "t"
  run_pace = convert_to_seconds(check_digits_time(ARGV[1]))
  run_distance = check_digits_distance(ARGV[2])
  run_time = calculate_timerun(run_pace, run_distance).to_i
  raise_negative(run_time)
  puts convert_to_clocktime(run_time)
when "d"
  run_time = convert_to_seconds(check_digits_time(ARGV[1]))
  run_pace = convert_to_seconds(check_digits_time(ARGV[2]))
  run_distance = calculate_distance(run_time, run_pace)
  puts run_distance
else
  raise ArgumentError, "You have to choose p (pace), t (time run) or d (distance)."  
end