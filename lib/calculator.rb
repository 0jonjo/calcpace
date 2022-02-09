require_relative 'ruby-calcpace'

run = Run.new

puts "Insert time run (XX:XX:XX) or ENTER"
gets_time = gets.chomp
run.set_time(run.convert_to_seconds(gets_time))
puts "Insert distance (XX.XX) km or ENTER"
run.set_distance(gets.chomp.to_f)
puts "Insert pace (XX:XX:XX) or ENTER"
gets_pace = gets.chomp
run.set_pace(run.convert_to_seconds(gets_pace))

if gets_pace.empty?
  run_pace_calculate = run.calculate_pace(run.time, run.distance)
  run.set_pace(run_pace_calculate)
elsif gets_time.empty?
  run_time_calculate = run.calculate_timerun(run.pace, run_distance)
  run.set_time(run_time_calculate)
elsif run.distance.zero?
  run.set_distance(run.calculate_distance(run.time, run.pace))
else 
  raise ArgumentError, "It only takes two pieces of data to calculate something."  
end

puts run.informations_to_print