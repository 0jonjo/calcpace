class Run

  attr_reader :time, :pace, :distance, :mph

  def initialize time, pace, distance, mph
    @time = time
    @pace = pace
    @distance = distance
    @mph = mph
  end  

  def set_time time_run
    if time_run.negative?
      raise "Time can't be negative."
    else    
      @time = time_run
    end  
  end

  def set_pace pace_run 
    if pace_run.negative?
      raise "Pace can't be negative."  
    else
      @pace = pace_run
    end
  end

  def set_distance distance_run
    if distance_run.negative?
      raise "Distance can't be negative."  
    else
      @distance = distance_run
    end
  end  

  def set_mph true_or_false
    @mph = true_or_false
  end    

  def calculate_pace
    @pace = @time / @distance 
    if @pace.negative? || @pace == 0
      raise ("Can't accept zero or negative values.")
    else
      @pace
    end  
  end

  def calculate_timerun 
    @time = @pace * @distance
    if @time.negative? || @time == 0
      raise ("Can't accept zero or negative values.")
    else
      @time
    end  
  end

  def calculate_distance
    @distance = @time / @pace
    if @distance.negative? || @distance == 0
      raise ("Can't accept zero or negative values.")
    else
      @distance
    end  
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
    if seconds.negative? || seconds == 0
      raise "Clocktime can't be zero or negative."
    else  
      Time.at(seconds).utc.strftime("%H:%M:%S")
    end
  end
end    