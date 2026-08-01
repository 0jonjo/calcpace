require './lib/calcpace'
require './lib/calcpace/fitness_predictor'
calc = Calcpace.new
puts calc.predict_time_from_vo2max(50, 'marathon')
