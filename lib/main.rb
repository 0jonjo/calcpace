require_relative 'run'

run = Run.new(0, 0, 0)
run.check_argv_length

case ARGV[0][0].downcase
when "p"
  run.set_time(run.convert_to_seconds(run.check_digits_time(ARGV[1]))) 
  run.set_distance(run.check_digits_distance(ARGV[2])) 
  run.set_pace(run.calculate_pace(run.time, run.distance).to_i)
  puts run.convert_to_clocktime(run.pace)
when "t"  
  run.set_pace(run.convert_to_seconds(run.check_digits_time(ARGV[1]))) 
  run.set_distance(run.check_digits_distance(ARGV[2]))
  run.set_time(run.calculate_timerun(run.pace, run.distance).to_i)  
  puts run.convert_to_clocktime(run.time)
when "d"
  run.set_time(run.convert_to_seconds(run.check_digits_time(ARGV[1]))) 
  run.set_pace(run.convert_to_seconds(run.check_digits_time(ARGV[2]))) 
  run.set_distance(run.calculate_distance(run.time, run.pace))
  puts run.distance  
else 
  raise ArgumentError, "You have to choose p (pace), t (time run) or d (distance)."  
end