# frozen_string_literal: true

require_relative 'run_calculate'
require_relative 'run_check'
require_relative 'run_convert'

check_argv_length(ARGV)
check_digits_time(ARGV[1])
time_or_pace = convert_to_seconds((ARGV[1]))
distance_or_pace = ARGV[2]
raise_negative(check_digits_distance(distance_or_pace))

puts calculate(ARGV[0][0].downcase, time_or_pace, distance_or_pace)
