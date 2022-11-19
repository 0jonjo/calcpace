module RunCalc
 
  def calculate_pace(time, distance) 
    pace = time / distance 
    Run.raise_negative(pace)
    Run.raise_zero(pace)
  end

  def calculate_timerun(pace, distance) 
    time = pace * distance
    Run.raise_negative(time)
    Run.raise_zero(time) 
  end

  def calculate_distance(time, pace)
    distance = (time.to_f) / pace
    Run.raise_negative(distance)
    Run.raise_zero(distance) 
  end  
end    