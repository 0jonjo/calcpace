require_relative 'run'

run = Run.new(0, 0, 0)
Run.check_argv_length

case ARGV[0]
when "p"
  run.set_time(Run.convert_to_seconds(Run.check_digits_time(ARGV[1]))) 
  run.set_distance(Run.check_digits_distance(ARGV[2])) 
  run.calculate_pace
when "t"  
  run.set_pace(Run.convert_to_seconds(Run.check_digits_time(ARGV[1]))) 
  run.set_distance(Run.check_digits_distance(ARGV[2]))
  run.calculate_timerun
when "d"
  run.set_time(Run.convert_to_seconds(Run.check_digits_time(ARGV[1]))) 
  run.set_pace(Run.convert_to_seconds(Run.check_digits_time(ARGV[2]))) 
  run.calculate_distance  
else 
  raise ArgumentError, "You have to choose p (pace), t (time run) or d (distance)."  
end
 
puts run