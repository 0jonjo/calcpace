# frozen_string_literal: true

require_relative 'calcpace/calculator'
require_relative 'calcpace/checker'
require_relative 'calcpace/converter'
require_relative 'calcpace/converter_chain'
require_relative 'calcpace/errors'
require_relative 'calcpace/pace_calculator'

# Calcpace - A Ruby gem for pace, distance, and time calculations
#
# Calcpace provides methods to calculate and convert values related to pace,
# distance, time, and speed. It supports various time formats and 42 different
# unit conversions.
#
# @example Basic velocity calculation
#   calc = Calcpace.new
#   calc.velocity(3600, 12000) #=> 3.333... (12000m in 3600s = 3.33 m/s)
#
# @example Time string calculations
#   calc = Calcpace.new
#   calc.checked_pace('01:00:00', 10) #=> 360.0 (1 hour / 10 km = 6:00/km pace)
#   calc.clock_pace('01:00:00', 10)   #=> '00:06:00'
#
# @example Unit conversions
#   calc = Calcpace.new
#   calc.convert(10, :km_to_mi)      #=> 6.21371 (10 km = 6.21 miles)
#   calc.convert(1, 'm_s_to_km_h')   #=> 3.6 (1 m/s = 3.6 km/h)
#
# @see https://github.com/0jonjo/calcpace
class Calcpace
  include Calculator
  include Checker
  include Converter
  include ConverterChain
  include PaceCalculator

  # Creates a new Calcpace instance
  #
  # @return [Calcpace] a new instance ready to perform calculations
end
