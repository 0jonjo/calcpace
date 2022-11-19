module RunCheck
  def check_argv_length
    (raise "It must be exactly three arguments") if ARGV.length != 3  
  end

  def check_digits_distance distance_string
    distance_string = "0" if distance_string == ''
    (distance_string =~ /\d/) ? distance_string.to_f : (raise "It must be a X.X number")   
  end

  def check_digits_time time_string
    return time_string = '' if time_string == ''
    time_string =~ /\d{0,2}(:|-)*?\d{1,2}(:|-)\d{1,2}/ ? time_string.gsub("-", ":") : (raise "It must be a XX:XX:XX time")   
  end
end    