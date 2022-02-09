class Run

  attr_reader :time, :pace, :distance

  def set_time(time_run)
    if time_run.negative? || time_run == 0
      raise "Time can't be zero or negative."
    else    
      @time = time_run
    end  
  end

  def set_pace(pace_run)
    if pace_run.negative? || pace_run == 0
      raise "Pace can't be zero or negative."  
    else
      @pace = pace_run
    end
  end

  def set_distance(distance_run)
    if distance_run.negative?
      raise "Distance can't be negative."  
    else
      @distance = distance_run
    end
  end  

  def convert_to_seconds(time)
    hour, minute, seconds = time.split(':')
    adjustedtime = ((hour.to_i)*3600) + ((minute.to_i)*60) + seconds.to_i
  end

  def convert_to_clocktime(seconds)
    if seconds.negative? || seconds == 0
      raise "Clocktime can't be zero or negative."
    else  
      Time.at(seconds).utc.strftime("%H:%M:%S")
    end
  end

  def calculate_pace(time, distance)
    @calculate_pace = time / distance 
    if @calculate_pace.negative? || @calculate_pace == 0
      raise ("Can't accept zero or negative values.")
    else
      @calculate_pace
    end  
    
  end

  def calculate_timerun(pace, distance)
    @calculate_timerun = pace * distance
    if @calculate_timerun.negative? || @calculate_timerun == 0
      raise ("Can't accept zero or negative values.")
    else
      @calculate_timerun
    end  
  end

  def calculate_distance(time, pace)
    @calculate_distance = time / pace
    if @calculate_distance.negative? || @calculate_distance == 0
      raise ("Can't accept zero or negative values.")
    else
      @calculate_distance
    end  
  end  

  def informations_to_print
    "You ran #{@distance} km in #{convert_to_clocktime(@time)} at #{convert_to_clocktime(@pace)} pace."
  end
end    