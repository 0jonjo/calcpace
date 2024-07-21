# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'calcpace'
  s.version     = '1.1.1'
  s.summary     = 'Calcpace: calculate time, distance, pace, velocity and convert distances in an easy and precise way.'
  s.description = 'Calcpace is a Ruby gem that helps with calculations related to running/cycling activities or general purposes involving distance and time. It can calculate pace, total time, and distance. It also converts distances between miles and kilometers and check formats of time and distance. The results are provided in a readable format, with times in HH:MM:SS or seconds and distances in X.X format. If you need, the gem supports BigDecimal to handle the calculations, '
  s.authors     = ['Joao Gilberto Saraiva']
  s.email       = 'joaogilberto@tuta.io'
  s.files       = ['lib/calcpace.rb', 'lib/calcpace/calculator.rb', 'lib/calcpace/checker.rb', 'lib/calcpace/converter.rb']
  s.test_files  = ['test/calcpace/test_calculator.rb', 'test/calcpace/test_checker.rb', 'test/calcpace/test_converter.rb']
  s.add_development_dependency 'minitest', '~> 5.14'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rake-compiler', '~> 1.0'
  s.add_development_dependency 'rdoc', '~> 6.2'
  s.add_development_dependency 'rubocop', '~> 0.79'
  s.add_development_dependency 'rubocop-minitest', '~> 0.11'
  s.required_ruby_version = '>= 2.7.0'
  s.post_install_message = "It's time to calculate! Thank you for installing Calcpace."
  s.metadata    = { 'source_code_uri' => 'https://github.com/0jonjo/calcpace' }
  s.homepage    = 'https://github.com/0jonjo/calcpace'
  s.license     = 'MIT'
end
