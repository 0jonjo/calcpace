require './lib/calcpace'
calc = Calcpace.new
puts calc.race_times_from_vo2max(50, races: [10.0, '5k']).inspect
