class Run

  attr_reader :time, :pace, :distance, :mph

  def initialize time, pace, distance, mph
    @time = time
    @pace = pace
    @distance = distance
    @mph = mph
  end  

  def set_time time_run
    Run.raise_negative(time_run)   
    @time = time_run
  end

  def set_pace pace_run 
    Run.raise_negative(pace_run)
    @pace = pace_run
  end

  def set_distance distance_run
    Run.raise_negative(distance_run)
    @distance = distance_run
  end  

  def set_mph true_or_false
    if true_or_false == true || true_or_false == false
      @mph = true_or_false
    else
      raise "MPH can be only true or false."
    end
  end    

  def calculate_pace
    @pace = @time / @distance 
    Run.raise_negative(@pace)
    Run.raise_zero(@pace) 
  end

  def calculate_timerun 
    @time = @pace * @distance
    Run.raise_negative(@time)
    Run.raise_zero(@time)  
  end

  def calculate_distance
    @distance = @time / @pace
    Run.raise_negative(@distance)
    Run.raise_zero(@distance) 
  end  

  def choose_calculus 
    if @pace.zero?
      calculate_pace
    elsif @time.zero?
      calculate_timerun
    elsif @distance.zero?
      calculate_distance
    else 
      raise ArgumentError, "It only takes two pieces of data to calculate something."  
    end
  end

  def to_s
    "You ran #{@distance} " + (@mph ? "mph" : "km") + " in " + Run.convert_to_clocktime(@time) + " at " + Run.convert_to_clocktime(@pace) + " pace."
  end

  def self.convert_to_seconds time
    hour, minute, seconds = time.split(':')
    ((hour.to_i)*3600) + ((minute.to_i)*60) + seconds.to_i
  end

  def self.convert_to_clocktime seconds
    Run.raise_negative(seconds)
    Run.raise_zero(seconds) 
    Time.at(seconds).utc.strftime("%H:%M:%S")
  end
  
  def self.raise_negative number
    if number.negative?
      raise "It can't be negative."
    else
      number
    end    
  end

  def self.raise_zero number
    if number.zero?
      raise "It can't be zero."
    else
      number
    end    
  end
end    