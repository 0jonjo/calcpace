# frozen_string_literal: true

def convert_to_seconds(time)
  hour, minute, seconds = time.split(':').map(&:to_i)
  (hour * 3600) + (minute * 60) + seconds
end

def convert_to_clocktime(seconds)
  Time.at(seconds).utc.strftime('%H:%M:%S')
end
