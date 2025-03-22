# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'calcpace'
  s.version     = '1.5.3'
  s.summary     = 'Calcpace: calculate total, distance, speed, and convert distances and velocity in an easy way.'
  s.description = 'It is designed for calculations related to distance, speed and time. The gem also supports conversion to 42 different units of distance and velocity, including metric, nautical and imperial units.'
  s.authors     = ['Joao Gilberto Saraiva']
  s.email       = 'joaogilberto@tuta.io'
  s.files       = ['lib/calcpace.rb', 'lib/calcpace/calculator.rb', 'lib/calcpace/checker.rb',
                   'lib/calcpace/converter.rb']
  s.test_files  = ['test/calcpace/test_calculator.rb', 'test/calcpace/test_checker.rb',
                   'test/calcpace/test_converter.rb']
  s.add_development_dependency 'minitest', '~> 5.25'
  s.add_development_dependency 'rake', '~> 13.2'
  s.add_development_dependency 'rake-compiler', '~> 1.0'
  s.add_development_dependency 'rdoc', '~> 6.2'
  s.add_development_dependency 'rubocop', '~> 1.69'
  s.required_ruby_version = '>= 2.7.0'
  s.post_install_message = "It's time to calculate! Thank you for installing Calcpace."
  s.metadata    = { 'source_code_uri' => 'https://github.com/0jonjo/calcpace' }
  s.homepage    = 'https://github.com/0jonjo/calcpace'
  s.license     = 'MIT'
end
