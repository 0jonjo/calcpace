require_relative 'ruby-calcpace'

run = Run.new

puts "Insert time run (XX:XX:XX) or ENTER"
run.time = gets.chomp
puts "Insert distance (XX.XX) km or ENTER"
run.distance = gets.chomp.to_f
puts "Insert pace (XX:XX:XX) or ENTER"
run.pace = gets.chomp

if run.pace == ''
  run_time_adapted = run.convert_to_seconds(run.time)
  run_pace_calculate = run.calculate_pace(run_time_adapted, run.distance)
  run.pace = run.convert_to_clocktime(run_pace_calculate)
elsif run.time == ''
  run_pace_adapted = run.convert_to_seconds(run.pace)
  run_time_calculate = run.calculate_timerun(run_pace_adapted, run.distance)
  run.time = run.convert_to_clocktime(run_time_calculate)
elsif run.distance == 0.0
  run_time_adapted = run.convert_to_seconds(run.time)
  run_pace_adapted = run.convert_to_seconds(run.pace)
  run.distance = run.calculate_distance(run_time_adapted, run_pace_adapted)
else 
  raise ArgumentError, "It only takes two pieces of data to calculate something."  
end

puts run.informations_to_print