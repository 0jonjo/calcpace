require_relative 'ruby-calcpace'

run = Run.new

puts "Insert time run (XX:XX:XX) or ENTER"
gets_time = gets.chomp
run.set_time(run.convert_to_seconds(gets_time))
puts "Insert distance (XX.XX) km or ENTER"
gets_distance = gets.chomp.to_f
puts "Insert pace (XX:XX:XX) or ENTER"
gets_pace = gets.chomp

if gets_pace.empty?
  set_clocktime(gets_time)
  run_time_adapted = run.convert_to_seconds(gets_time)
  run_pace_calculate = run.calculate_pace(run_time_adapted, gets_distance)
  run.set_pace(run.convert_to_clocktime(run_pace_calculate))
elsif gets_time.empty?
  set_pacetime(gets_pace)
  run_pace_adapted = run.convert_to_seconds(gets_pace)
  run_time_calculate = run.calculate_timerun(run_pace_adapted, run_distance)
  run.set_time(run.convert_to_clocktime(run_time_calculate))
elsif gets_distance.zero?
  set_clocktime(gets_time)
  set_clockpace(gets_pace)
  run_time_adapted = run.convert_to_seconds(gets_time)
  run_pace_adapted = run.convert_to_seconds(gets_pace)
  run.set_distance(run.calculate_distance(run_time_adapted, run_pace_adapted))
else 
  raise ArgumentError, "It only takes two pieces of data to calculate something."  
end

puts run.informations_to_print