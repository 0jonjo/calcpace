class Run

  attr_reader :time, :pace, :distance

  def initialize time, pace, distance
    @time = time
    @pace = pace
    @distance = distance
  end  

  def set_time time_run
    Run.raise_negative(time_run)   
    @time = time_run if time_run.integer?
  end

  def set_pace pace_run 
    Run.raise_negative(pace_run)
    @pace = pace_run if pace_run.integer?
  end

  def set_distance distance_run
    Run.raise_negative(distance_run)
    @distance = distance_run
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
    @distance = @time.to_f / @pace
    Run.raise_negative(@distance)
    Run.raise_zero(@distance) 
  end  

  def to_s
    "You ran #{@distance.round(2)}" + " km in " + Run.convert_to_clocktime(@time) + " at " + Run.convert_to_clocktime(@pace) + " pace."
  end

  def self.check_argv_length
    (raise "It must be exactly three arguments") if ARGV.length != 3  
  end

  def self.check_digits_distance distance_string
    distance_string = "0" if distance_string == ''
    (distance_string =~ /\d/) ? distance_string.to_f : (raise "It must be a X.X number")   
  end

  def self.check_digits_time time_string
    return time_string = '' if time_string == ''
    time_string =~ /\d{0,2}(:|-)*?\d{1,2}(:|-)\d{1,2}/ ? time_string.gsub("-", ":") : (raise "It must be a XX:XX:XX time")   
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