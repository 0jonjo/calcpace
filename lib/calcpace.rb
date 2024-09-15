# frozen_string_literal: true

require_relative 'calcpace/calculator'
require_relative 'calcpace/checker'
require_relative 'calcpace/converter'

# Main class to calculate velocity, pace, time, distance and velocity
class Calcpace
  include Calculator
  include Checker
  include Converter

  attr_reader :bigdecimal

  def initialize; end
end
