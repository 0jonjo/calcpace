require_relative 'run'

run = Run.new

puts "Insert time run (XX:XX:XX) or ENTER"
run.set_time(Run.convert_to_seconds(gets.chomp))
puts "Insert distance (XX.XX) km or ENTER"
run.set_distance(gets.chomp.to_f)
puts "Insert pace (XX:XX:XX) or ENTER"
run.set_pace(Run.convert_to_seconds(gets.chomp))

if run.pace.zero?
  run.set_pace(run.calculate_pace(run.time, run.distance))
elsif run.time.zero?
  run.set_time(run.calculate_timerun(run.pace, run.distance))
elsif run.distance.zero?
  run.set_distance(run.calculate_distance(run.time, run.pace))
else 
  raise ArgumentError, "It only takes two pieces of data to calculate something."  
end

puts run