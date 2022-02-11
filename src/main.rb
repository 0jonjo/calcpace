require_relative 'run'

run = Run.new(0, 0, 0)

puts "Insert time run (XX:XX:XX) or ENTER"
run.set_time(Run.convert_to_seconds(gets.chomp))
puts "Insert distance (XX.XX) km or ENTER"
run.set_distance(gets.chomp.to_f)
puts "Insert pace (XX:XX:XX) or ENTER"
run.set_pace(Run.convert_to_seconds(gets.chomp))

run.choose_calculus

puts run