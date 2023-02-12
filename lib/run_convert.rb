def convert_to_seconds(time)
  hour, minute, seconds = time.split(':')
  ((hour.to_i)*3600) + ((minute.to_i)*60) + seconds.to_i
end

def convert_to_clocktime(seconds)
  Time.at(seconds).utc.strftime("%H:%M:%S")
end
