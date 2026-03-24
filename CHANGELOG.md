# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.9.0] - 2026-03-24

### Added
- Cameron race predictor (`CameronPredictor` module) — alternative to Riegel for predicting race times
  - `predict_time_cameron` — predicts race time in seconds using the Cameron formula
  - `predict_time_cameron_clock` — same, returned as `HH:MM:SS` string
  - `predict_pace_cameron` — predicted pace in seconds per kilometer
  - `predict_pace_cameron_clock` — same, returned as `HH:MM:SS` string
  - Formula: `T2 = T1 × (D2/D1) × [f(D1) / f(D2)]` where `f(d) = a + b × e^(-d/c)`, constants calibrated for km
  - The exponential correction is larger when predicting from shorter distances, reflecting the greater anaerobic contribution at shorter race distances
  - Accepts the same input formats as `RacePredictor`: string (`HH:MM:SS`, `MM:SS`) or numeric seconds
  - 18 test cases covering standard predictions, round-trip consistency, clock format outputs, and error handling

## [1.8.2] - 2026-03-07

### Added
- GitHub Actions workflow for automated gem publishing to RubyGems.org on push to `main` when `lib/calcpace/version.rb` changes
- Trusted publishing via OIDC (no API key required) using `rubygems/release-gem` action
- Automatic GitHub Release creation with generated notes on each publish
- `bundler/gem_tasks` added to `Rakefile` to support `rake release` and related tasks
- SimpleCov integration for code coverage measurement
- RuboCop lint job to CI pipeline
- YARD documentation for all previously undocumented public methods in `Calculator` (`checked_velocity`, `clock_velocity`, `checked_pace`, `clock_pace`, `time`, `checked_time`, `clock_time`, `distance`, `checked_distance`)

### Changed
- Minimum required Ruby version bumped from 2.7 to 3.2
- CI matrix updated: removed EOL Ruby versions (2.7, 3.0, 3.1), added Ruby 4.0
- CI lint job uses `.ruby-version` file instead of a hardcoded version
- Bundler updated to 4.0.6
- `Rakefile.rb` renamed to `Rakefile` (standard convention)
- `PaceConverter` constants `MI_TO_KM` and `KM_TO_MI` consolidated into `Converter::Distance`
- Negative and positive split calculations refactored to share common logic
- Test files refactored to inherit from shared `CalcpaceTest` base class

## [1.8.0] - 2026-02-14

### Added
- Pace conversion module for converting running pace between kilometers and miles
  - `convert_pace` method with support for both symbol and string format conversions
  - `pace_km_to_mi` convenience method for kilometers to miles conversion
  - `pace_mi_to_km` convenience method for miles to kilometers conversion
  - Support for both numeric (seconds) and string (MM:SS) input formats
- Race splits calculator for pacing strategies
  - `race_splits` method to calculate cumulative split times for races
  - Support for even pace, negative splits (progressive), and positive splits (conservative) strategies
  - Flexible split distances: standard race distances ('5k', '1mile') or custom distances (numeric km)
  - Works with all standard race distances including marathon, half marathon, 10K, 5K, and mile races
- Race time predictor using Riegel formula
  - `predict_time` and `predict_time_clock` methods to predict race times at different distances
  - `predict_pace` and `predict_pace_clock` methods to calculate predicted pace for target races
  - `equivalent_performance` method to compare performances across different race distances
  - Based on proven Riegel formula: T2 = T1 × (D2/D1)^1.06
  - Detailed explanation of the formula and its applications in README
- Additional race distances for international races
  - `1mile` - 1.60934 kilometers
  - `5mile` - 8.04672 kilometers
  - `10mile` - 16.0934 kilometers
- Comprehensive test suites
  - 30+ test cases for pace conversions
  - 30+ test cases for race splits covering all strategies and edge cases
  - 35+ test cases for race predictions covering various scenarios

### Changed
- Expanded `RACE_DISTANCES` to include popular US/UK race distances
- Updated README with pace conversion, race splits, and race prediction examples
- Improved documentation with practical examples, use cases, and formula explanations

## [1.7.0] - Released

### Added
- RuboCop configuration for code style consistency
- CHANGELOG.md for tracking project changes
- Comprehensive YARD documentation for all public methods
- Race pace calculator for standard distances (5K, 10K, half-marathon, marathon)
  - `race_time` and `race_time_clock` methods for calculating finish times
  - `race_pace` and `race_pace_clock` methods for calculating required paces
  - `list_races` method to see available race distances
- `UnsupportedUnitError` for better error handling
- Comprehensive test suite with edge cases and error scenarios
- Test helper utilities for better test organization

### Changed
- Improved error messages with more context throughout the gem
- Enhanced validation for edge cases
- Better method organization and code structure
- Optimized `convert_to_seconds` method using case statement
- Improved error handling in `constant` method with nested rescue

### Fixed
- Minor code style inconsistencies
- Typo in README: `converto_to_clocktime` → `convert_to_clocktime`

## [1.6.0] - Previous Release

### Added
- Custom error classes for better error handling
- `NonPositiveInputError` for invalid numeric inputs
- `InvalidTimeFormatError` for invalid time format inputs

### Changed
- Improved error handling throughout the gem

## [1.5.0] and earlier

See git history for changes in earlier versions.

[Unreleased]: https://github.com/0jonjo/calcpace/compare/v1.6.0...HEAD
[1.6.0]: https://github.com/0jonjo/calcpace/releases/tag/v1.6.0
