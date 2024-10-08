# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'calcpace'
  s.version     = '1.4.0'
  s.summary     = 'Calcpace: calculate total, distance, velocity and convert distances in an easy way.'
  s.description = 'Calcpace is designed for calculations and conversions related to distance and time. It can calculate velocity, pace, total time, and distance and it supports conversion to 26 different units, including kilometers, miles, meters, and feet.'
  s.authors     = ['Joao Gilberto Saraiva']
  s.email       = 'joaogilberto@tuta.io'
  s.files       = ['lib/calcpace.rb', 'lib/calcpace/calculator.rb', 'lib/calcpace/checker.rb',
                   'lib/calcpace/converter.rb']
  s.test_files  = ['test/calcpace/test_calculator.rb', 'test/calcpace/test_checker.rb',
                   'test/calcpace/test_converter.rb']
  s.add_development_dependency 'minitest', '~> 5.14'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rake-compiler', '~> 1.0'
  s.add_development_dependency 'rdoc', '~> 6.2'
  s.add_development_dependency 'rubocop', '~> 1.66'
  s.required_ruby_version = '>= 2.7.0'
  s.post_install_message = "It's time to calculate! Thank you for installing Calcpace."
  s.metadata    = { 'source_code_uri' => 'https://github.com/0jonjo/calcpace' }
  s.homepage    = 'https://github.com/0jonjo/calcpace'
  s.license     = 'MIT'
end
