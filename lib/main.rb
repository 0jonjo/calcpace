require_relative 'run'

run = Run.new(0, 0, 0, false)

Run.check_argv_length

choose = ARGV[0]
if choose.downcase == "p"
  run.set_time(Run.convert_to_seconds(Run.check_digits_time(ARGV[1]))) 
  run.set_distance(Run.check_digits_distance(ARGV[2])) 
  run.calculate_pace
elsif choose.downcase == "t"
  run.set_pace(Run.convert_to_seconds(Run.check_digits_time(ARGV[1]))) 
  run.set_distance(Run.check_digits_distance(ARGV[2]))
  run.calculate_timerun
elsif choose.downcase == "d"
  run.set_time(Run.convert_to_seconds(Run.check_digits_time(ARGV[1]))) 
  run.set_pace(Run.convert_to_seconds(Run.check_digits_time(ARGV[2]))) 
  run.calculate_distance
else 
  raise ArgumentError, "You have to choose p (pace), t (time run) or d (distance)."  
end
  
puts run