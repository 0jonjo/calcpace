class Run

  attr_reader :time, :pace, :distance

  def time(time_run)
    @time = time_run
  end

  def pace(pace_run)
    @pace = pace_run
  end

  def distance(distance_run)
    if distance_run.negative? || distance_run.zero?
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
    if seconds.negative?
      raise "Clocktime can't be zero or negative"
    else  
      Time.at(seconds).utc.strftime("%H:%M:%S")
    end
  end

  def calculate_pace(time, distance)
    @pace = time / distance 
  end

  def calculate_timerun(pace, distance)
    @time = pace * distance 
  end

  def calculate_distance(time, pace)
    @distance = time / pace
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