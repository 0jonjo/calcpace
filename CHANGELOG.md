# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.8.0] - Unreleased

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
- Additional race distances for international races
  - `1mile` - 1.60934 kilometers
  - `5mile` - 8.04672 kilometers
  - `10mile` - 16.0934 kilometers
- Comprehensive test suites
  - 30+ test cases for pace conversions
  - 30+ test cases for race splits covering all strategies and edge cases

### Changed
- Expanded `RACE_DISTANCES` to include popular US/UK race distances
- Updated README with pace conversion and race splits examples
- Improved documentation with practical examples and use cases

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
