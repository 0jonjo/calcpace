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
