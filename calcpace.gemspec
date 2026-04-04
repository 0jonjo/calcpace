# frozen_string_literal: true

require_relative 'lib/calcpace/version'

Gem::Specification.new do |spec|
  spec.name          = 'calcpace'
  spec.version       = Calcpace::VERSION
  spec.authors       = ['João Gilberto Saraiva']
  spec.email         = ['joaogilberto@tuta.io']

  spec.summary       = 'Pace, distance, GPS track analysis, and VO2max calculations for runners and cyclists.'
  spec.description   = 'Ruby gem for running and cycling calculations: pace, time, distance, unit conversions (30+ units), race predictions (Riegel & Cameron), GPS track analysis (Haversine, elevation gain, per-km splits), and VO2max estimation (Daniels & Gilbert).'
  spec.homepage      = 'https://github.com/0jonjo/calcpace'
  spec.metadata['source_code_uri'] = spec.homepage
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
