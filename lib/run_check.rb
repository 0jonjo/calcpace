# frozen_string_literal: true

def check_argv_length(argv)
  raise 'It must be exactly three arguments' if argv.length != 3
end

def check_argv_modal(argv_modal)
  raise ArgumentError, 'You have to choose p (pace), t (time run) or d (distance).' unless %w[p d t].include?(argv_modal)
end

def checks_argv(argv)
  check_argv_length(argv)
  check_argv_modal(argv[0][0].downcase)
  check_digits_time(argv[1])
  check_digits_distance(argv[2])
  raise_negative(argv[2])
end

def check_digits_distance(distance_string)
  raise 'It must be a X.X number' unless distance_string =~ /\d/
  distance_string.to_f
end

def check_digits_time(time_string)
  raise 'It must be a XX:XX:XX time' unless time_string =~ /\d{0,2}(:|-)*?\d{1,2}(:|-)\d{1,2}/
  time_string.gsub('-', ':')
end

def raise_negative(number)
  raise "It can't be negative." if number.to_i.negative?
end


