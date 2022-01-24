class Run

  attr_accessor :time, :pace, :distance

  def convert_to_seconds(time)
    hour, minute, seconds = time.split(':')
    adjustedtime = ((hour.to_i)*3600) + ((minute.to_i)*60) + seconds.to_i
  end

  def convert_to_clocktime(seconds)
    Time.at(seconds).utc.strftime("%H:%M:%S")
  end

  def calculate_pace(time, distance)
    pace = time / distance 
  end

  def calculate_timerun(pace, distance)
    time = pace * distance 
  end

  def calculate_distance(time, pace)
    distance = time / pace
  end  

  def informations_to_print
    "You ran #{distance} km in #{time} at #{pace} pace."
  end
end    
