class Run

  attr_reader :time, :pace, :distance

  def time(time_run)
    if time_run.negative? || time_run == 0
      raise "Time can't be zero or negative"
    else    
      @time = time_run
    end  
  end

  def pace(pace_run)
    if pace_run.negative? || pace_run == 0
      raise "Pace can't be zero or negative"  
    else
      @pace = pace_run
    end
  end

  def distance(distance_run)
    if distance_run.negative? || distance_run == 0
      raise "Distance can't be zero or negative"  
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
      raise "Clocktime can't be zero or negative"
    else  
      Time.at(seconds).utc.strftime("%H:%M:%S")
    end
  end

  def calculate_pace(time, distance)
    @calculate_pace = time / distance 
    if @calculate_pace.negative? || @calculate_pace == 0
      raise ("Can't accept zero or negative values")
    else
      @calculate_pace
    end  
    
  end

  def calculate_timerun(pace, distance)
    @calculate_timerun = pace * distance
    if @calculate_timerun.negative? || @calculate_timerun == 0
      raise ("Can't accept zero or negative values")
    else
      @calculate_timerun
    end  
  end

  def calculate_distance(time, pace)
    @calculate_distance = time / pace
    if @calculate_distance.negative? || @calculate_distance == 0
      raise ("Can't accept zero or negative values")
    else
      @calculate_distance
    end  
  end  

  def informations_to_print
    "You ran #{@distance} km in #{@time} at #{@pace} pace."
  end
end    

# run = Run.new
# run.time("01:00:00")
# run.pace("00:06:00")
#run.distance(10) 

# p run.time 