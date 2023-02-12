def calculate_pace(time, distance) 
  pace = time / distance 
end

def calculate_timerun(pace, distance) 
  time = pace * distance
end

def calculate_distance(time, pace)
  distance = (time.to_f) / pace
end