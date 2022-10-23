require_relative 'run'

run = Run.new(0, 0, 0)
Run.check_argv_length

case ARGV[0]
when "p"
  run.set_time(Run.convert_to_seconds(Run.check_digits_time(ARGV[1]))) 
  run.set_distance(Run.check_digits_distance(ARGV[2])) 
  run.calculate_pace
  puts Run.convert_to_clocktime(run.pace)
when "t"  
  run.set_pace(Run.convert_to_seconds(Run.check_digits_time(ARGV[1]))) 
  run.set_distance(Run.check_digits_distance(ARGV[2]))
  run.calculate_timerun
  puts Run.convert_to_clocktime(run.time)
when "d"
  run.set_time(Run.convert_to_seconds(Run.check_digits_time(ARGV[1]))) 
  run.set_pace(Run.convert_to_seconds(Run.check_digits_time(ARGV[2]))) 
  run.calculate_distance
  puts run.distance  
else 
  raise ArgumentError, "You have to choose p (pace), t (time run) or d (distance)."  
end