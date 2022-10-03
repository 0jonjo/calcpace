require_relative 'run'

run = Run.new(0, 0, 0, false)

puts "Insert any letter for MPH or ENTER for km"
run.set_mph(gets.chomp.empty? ? false : true)

puts "Insert time run (XX:XX:XX) or ENTER"
run.set_time(Run.convert_to_seconds(gets.chomp))
puts "Insert distance (XX.XX) or ENTER"
run.set_distance(Run.check_digits_distance(gets.chomp))
puts "Insert pace (XX:XX:XX) or ENTER"
run.set_pace(Run.convert_to_seconds(gets.chomp))

run.choose_calculus

puts run