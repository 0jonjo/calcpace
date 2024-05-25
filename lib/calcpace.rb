# frozen_string_literal: true

require_relative 'calcpace/calculator'
require_relative 'calcpace/checker'
require_relative 'calcpace/converter'

class Calcpace
  include Calculator
  include Checker
  include Converter

  def initialize; end
end

# Use module to convert a distance
# puts Calcpace.new.convert_distance(10, 'km')

# puts Calcpace.new.convert_distance(10, 'mi')

# puts Calcpace.new.pace('01:00:00', 10)

# puts Calcpace.new.total_time('00:05:00', 12)

# puts Calcpace.new.distance('01:00:00', '00:05:00')