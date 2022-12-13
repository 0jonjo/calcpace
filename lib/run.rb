require_relative 'run_calc'
require_relative 'run_convert'
require_relative 'run_check'

class Run
  include RunCalc
  include RunConvert
  include RunCheck

  attr_reader :time, :pace, :distance

  def initialize(time, pace, distance)
    @time = time
    @pace = pace
    @distance = distance
  end  

  def time=(time_run)
    Run.raise_negative(time_run)   
    @time = time_run if time_run.integer?
  end

  def pace=(pace_run) 
    Run.raise_negative(pace_run)
    @pace = pace_run if pace_run.integer?
  end

  def distance=(distance_run)
    Run.raise_negative(distance_run)
    @distance = distance_run
  end  
  
  def self.raise_negative(number)
    raise "It can't be negative." if number.negative?  
    number    
  end

  def self.raise_zero(number)
    raise "It can't be zero." if number.zero?
    number   
  end
end 