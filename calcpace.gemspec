# frozen_string_literal: true

require_relative 'lib/calcpace/version'

Gem::Specification.new do |spec|
  spec.name          = 'calcpace'
  spec.version       = Calcpace::VERSION
  spec.authors       = ['João Gilberto Saraiva']
  spec.email         = ['joaogilberto@tuta.io']

  spec.summary       = 'A Ruby gem for pace, distance, and time calculations.'
  spec.description   = 'Calcpace provides methods to calculate and convert values related to pace, distance, time, and speed. It supports various time formats and unit conversions.'
  spec.homepage      = 'https://github.com/0jonjo/calcpace'
  spec.metadata['source_code_uri'] = spec.homepage
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md" # TODO: Create a CHANGELOG.md

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
