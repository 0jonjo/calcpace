# frozen_string_literal: true

require_relative 'run_calculate'
require_relative 'run_check'
require_relative 'run_convert'

checks_argv(ARGV)

puts calculate(ARGV[0][0].downcase, convert_to_seconds(ARGV[1]), ARGV[2])
