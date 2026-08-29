# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.14.0] - 2026-08-29

### Added
- `compact:` keyword on every pace-producing method, so a caller can ask for the
  display format `convert_to_clocktime(compact: true)` introduced in 1.13.0
  without reformatting the string itself
  - `convert_pace(pace, conversion, compact: false)`
  - `pace_km_to_mi(pace_per_km, compact: false)`
  - `pace_mi_to_km(pace_per_mi, compact: false)`
  - `track_splits(points, split_km = 1.0, compact: false)` — only the `:pace`
    value changes; `:km` and `:elapsed` are numbers and stay as they are

  ```ruby
  calc.pace_km_to_mi('05:00')                # => "00:08:02"
  calc.pace_km_to_mi('05:00', compact: true) # => "8:02"
  calc.track_splits(points, 1.0, compact: true)
  # => [{ km: 1.0, elapsed: 312, pace: "5:12" }, ...]
  ```

  The default stays `compact: false` everywhere, byte-for-byte the previous
  output — the one exception is the negative-split fix below, which corrects a
  value that was arithmetically wrong. Input validation is untouched:
  a zero or negative pace still raises `Calcpace::NonPositiveInputError` and an
  unknown conversion still raises `ArgumentError` in both modes.

  Three places the two formats disagree about more than padding, all of them
  now reachable through the pace APIs:

  - A split pace slower than an hour per unit: the padded format keeps counting
    minutes (`"66:33"`), as `track_splits` always has, while the compact one
    rolls them into an hour field (`"1:06:33"`), consistent with every other
    compact duration in the gem. Past 24 hours per unit the gap widens —
    `"2248:18"` padded against `"37:28:18"` compact.
  - Durations past 24 hours, the day-prefix rule 1.13.0 documented for
    `convert_to_clocktime` alone, now visible through `convert_pace` too:
    `convert_pace(100_000, :km_to_mi)` #=> `"1 20:42:14"`, against
    `"44:42:14"` compact.
  - A negative split (see Fixed below), signed in both formats but padded to a
    different width: `"-00:40"` against `"-0:40"`.

### Fixed
- `track_splits` no longer misreports a negative split pace. A GPS track can
  step backwards in time — a watch resyncing its clock, a device paused and
  restarted, two segments merged out of order — which makes a split's elapsed
  time negative. The padded format rendered that through Ruby's floor division,
  so a −40 s split printed as `"-1:20"`; it now prints `"-00:40"`, and the
  compact format prints `"-0:40"`. Neither mode raises: bad GPS data has always
  been reported rather than blown up, and `compact: true` does not change that.
- `convert_pace`, `pace_km_to_mi` and `pace_mi_to_km` documented their return
  value as `'08:02'` when they have always returned the padded `'00:08:02'`.
  The docs now match the code; the code is unchanged.
- README and YARD examples for `track_distance`, `haversine_distance` and
  `track_splits` printed numbers their own input never produced (`0.87` km for
  a 1.51 km track, a `"05:12"` split for a `"06:55"` one). Every example is now
  the real output of the code above it.

## [1.13.0] - 2026-08-28

### Added
- `convert_to_clocktime(seconds, compact: true)` — the display format a runner
  reads, next to the padded format the gem already returned
  - drops the hour when it is zero and the leading zero of the most significant
    component, keeping two digits on everything after it:
    `convert_to_clocktime(292, compact: true)` #=> `'4:52'`,
    `convert_to_clocktime(45, compact: true)` #=> `'0:45'`,
    `convert_to_clocktime(5025, compact: true)` #=> `'1:23:45'`
  - past 24 hours it keeps counting hours (`100_000` #=> `'27:46:40'`) instead
    of the padded format's day prefix (`'1 03:46:40'`) — a day count brings back
    the padding and the extra unit the compact format exists to strip
  - fractional seconds truncate, as they already did in the padded format:
    `292.9` #=> `'4:52'`

  The default stays `compact: false`, byte-for-byte the previous output, so every
  existing caller is unaffected.

### Fixed
- `convert_to_clocktime` with a negative number now raises
  `Calcpace::NonPositiveInputError` instead of silently wrapping around
  (`-5` used to return `'23:59:55'`, a `Time.at` artifact). Zero remains a valid
  duration in both formats. Non-numeric input keeps raising as before.

## [1.12.1] - 2026-08-15

### Changed
- Development dependency bumps: rubocop 1.89, rdoc 8.0, simplecov 1.1, erb 6.0.7.
  No library code changes.

## [1.12.0] - 2026-08-01

### Added
- Fitness predictor — race times from a VO2max value, the inverse of
  `estimate_vo2max`
  - `predict_time_from_vo2max(vo2max, race, distance_unit: nil)`: predicted
    finish time in seconds. `race` accepts a standard race name ('5k',
    'marathon', '5mile', ...) or a numeric distance in kilometres (miles via
    `distance_unit: :mi`), same semantics as `training_paces_from_race`
  - `predict_time_from_vo2max_clock(...)`: same prediction as `HH:MM:SS`
  - `race_times_from_vo2max(vo2max, races: nil, unit: :km)`: one call returns a
    table of `time`, `time_clock`, `pace`, and `pace_clock` per race (default
    races: 5k, 10k, half marathon, marathon; `unit: :mi` for paces per mile)
  - VO2max inputs outside 10–100 ml/kg/min raise `ArgumentError`, where the
    Daniels & Gilbert model stops being physiologically meaningful

Predictions come from bisecting the Daniels & Gilbert curve on the time axis
(it has no closed-form inverse), so
`estimate_vo2max(d, predict_time_from_vo2max(v, d))` returns `v` back. Times
match Daniels' published VDOT table within a few seconds for the shorter races
and about a minute for the marathon.

No existing behaviour changed: the Riegel (`predict_time`) and Cameron
predictors are untouched.

## [1.11.0] - 2026-07-25

### Added
- Training zones improvements
  - `training_paces` and `training_paces_from_race` accept `unit: :mi` for
    pace bands per mile (default remains `:km`)
  - `hr_zones_from_max(hr_max:)`: five heart-rate zones from maximum heart
    rate only (%HRmax method) — fallback when resting heart rate is unknown
  - `training_paces_from_race` accepts standard race names ('10k', 'marathon',
    '5mile', ...) in addition to numeric kilometres, matching `predict_time`
    and `race_pace`
  - `distance_unit: :mi` keyword on `estimate_vo2max`, `estimate_detailed_vo2max`,
    `age_grade`, `age_grade_percent`, and `training_paces_from_race` — numeric
    distance inputs can now be given in miles (default remains kilometres)

### Changed
- `training_paces_from_race` resolves non-numeric distances as race names. Strings
  that v1.10.0 silently parsed with `to_f` change meaning: `'5mile'` was 5.0 km and
  is now the 5-mile standard distance (8.04672 km). Numeric strings (`'10'`,
  `'21.0975'`) keep working as before, in kilometres.
- `training_paces_from_race` with an unparseable distance (`nil`, `'banana'`) now
  raises `ArgumentError` ("Unknown race: ...") instead of
  `Calcpace::NonPositiveInputError`.
- Unknown `unit:` / `distance_unit:` values raise `Calcpace::UnsupportedUnitError`
  (inherits from `Calcpace::Error`) instead of `ArgumentError`. Unit keywords are
  now case-insensitive (`'MI'` works) and `nil` raises the same error instead of a
  `NoMethodError`.
- `unit: :mi` pace bands are computed natively per mile instead of being converted
  from the km bands, so they can differ by ±1 s from `pace_km_to_mi(km_band)` —
  the native value is the one without double rounding.
- Every mile-based factor now derives from the exact international mile
  (1 mi = 1609.344 m), which was previously truncated to 1.60934 in some places
  and exact in others. Affected values move by ~2.5e-6 relative:
  `convert(1, :mi_to_km)` 1.60934 → 1.609344, `convert(1, :km_to_mi)` 0.621371 →
  0.6213711922…, `convert(1, :mi_to_meters)` 1609.34 → 1609.344, the `mi_h`/`m_s`
  speed pairs, and `list_races` entries `'1mile'` (1.609344) and `'10mile'`
  (16.09344). Age-grading tolerance and pace bands now agree on mile length.
- Passing `distance_unit:` together with a race name (`training_paces_from_race('10k',
  t, distance_unit: :mi)`, `age_grade('10k', …, distance_unit: :mi)`) raises
  `ArgumentError` instead of silently ignoring the keyword — a standard race already
  carries its own distance.
- Race-name lookup is normalized in one place: `' 10K '` and `:MARATHON` now resolve
  everywhere (previously `PaceCalculator` did not strip whitespace), and `AgeGrading`
  uses the same "Unknown race: …" message wording as the rest of the gem.

### Fixed
- Age grading accepts mile distances as runners write them (`3.1`, `6.2`, `13.1`,
  `26.2` with `distance_unit: :mi`); the previous 0.001 km match window only
  accepted 6-decimal conversions.
- Unsupported age-grading distances report the input in the unit it was given
  instead of always labelling it "km".
- `estimate_detailed_vo2max` rejects a non-positive distance even when
  `elevation_gain_m` is positive (the elevation adjustment used to mask it).

## [1.10.0] - 2026-07-11

### Added
- Training Zones module (`TrainingZones`)
  - `training_paces(vo2max)`: personalized Easy/Marathon/Threshold/Interval/Repetition
    pace bands per km, inverting the Daniels & Gilbert velocity equation
  - `training_paces_from_race(distance_km, time)`: pace bands straight from a race result
  - `hr_zones(hr_max:, hr_rest:)`: five Karvonen (Heart Rate Reserve) heart-rate zones
  - Structured results (`PaceBand`, `HrZone`) with seconds and clock formats

## [1.9.10] - 2026-07-09

### Changed
- Refactor `TrackCalculator`: extract a single `dig_key` helper for symbol/string key access, removing duplicated fallback logic across coordinate, elevation, and time readers (no behavior change)

## [1.9.9] - 2026-06-17

### Changed
- Bump minitest from 5.x to 6.x
- Bump rdoc from 6.x to 7.x
- Bump rake, rubocop, parallel, and other dev dependencies to latest versions
- Drop Ruby 3.2 support (EOL March 2025); minimum is now Ruby 3.3

## [1.9.8] - 2026-05-23

### Added
- Contextualized VO2max estimation (`Vo2maxEstimator#estimate_detailed_vo2max`)
  - Confidence Score based on effort duration (Daniels & Gilbert optimal window)
  - Elevation Adjustment (Equivalent Flat Distance) using Naismith-based heuristic
  - Sub-maximal effort detection via Heart Rate intensity validation (%HRmax)
  - Structured result object (`Vo2maxResult`) with value, confidence, and metadata

## [1.9.7] - 2026-05-16

### Added
- Environmental Performance Adjustments module (`EnvironmentalAdjuster`)
  - Adjust race results and predictions based on temperature and altitude
  - Scientific basis: Matthew Ely et al. (2007) for heat and NCAA standards for altitude
  - Data-driven penalty tables stored in `lib/calcpace/data/environmental_factors.yml`
  - Support for interpolation between data points in penalty tables
  - Transparent return values including penalty percentage and factor breakdown
- New prediction methods with environmental support:
  - `predict_time_adjusted` (Riegel-based)
  - `predict_time_cameron_adjusted` (Cameron-based)
- `adjust_time` and `calculate_penalty` methods for direct environmental impact analysis

## [1.9.6] - 2026-05-15

### Changed
- Bump Ruby from 3.4.4 to 4.0.4

## [1.9.5] - 2026-05-02

### Added
- Age-grading module (`AgeGrading`) with:
  - `age_grade(distance_km, time, age:, sex:)`
  - `age_grade_percent(distance_km, time, age:, sex:)`
  - `age_grade_label(percent)`
- Versioned data file loader using YAML + `YAML.safe_load` from
  `lib/calcpace/data/wma_2023_road.yml`
- Interpolation support for in-between ages (e.g., 57 between 55 and 60)
- Initial road-race support: 5K, 10K, half marathon, marathon
- WMA 2023 one-year age factors integrated for `M`/`F` road distances in meters
  - Source: World Masters Athletics (WMA) competition rules documents
    https://world-masters-athletics.org/documents/competition-rules/
- Race-style age-factored time rounding up to the next hundredth
- Test suite for validation, interpolation, and error handling

## [1.9.4] - 2026-04-18

### Added
- Standard race distance support for **100K** (100.0 km)
  - Supported in `PaceCalculator`, `RacePredictor`, `CameronPredictor`, and `RaceSplits`
  - Updated `list_races` to include 100K
  - Added integration tests for 100K race distance across all modules

## [1.9.3] - 2026-04-05

### Added
- VO2max Estimator module (`Vo2maxEstimator`)
  - Daniels & Gilbert (1979) formula for VO2max estimation from race results
  - Performance level labels (Elite, Excellent, etc.)
- Improved time validation using strict `check_time` and `convert_to_seconds`
- Updated YARD documentation for all calculation methods

### Fixed
- Gemspec formatting and line length constraints
- README structure and documentation examples

## [1.9.2] - 2026-03-31

### Added
- Track Calculator module (`TrackCalculator`)
  - Haversine distance calculation for GPS coordinates
  - Elevation gain and loss analysis
  - Automated track splits based on GPS points

## [1.9.1] - 2026-03-30

### Changed
- Bump `json` from 2.19.0 to 2.19.2

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

[Unreleased]: https://github.com/0jonjo/calcpace/compare/v1.14.0...HEAD
[1.14.0]: https://github.com/0jonjo/calcpace/compare/v1.13.0...v1.14.0
[1.13.0]: https://github.com/0jonjo/calcpace/compare/v1.12.1...v1.13.0
[1.12.0]: https://github.com/0jonjo/calcpace/compare/v1.11.0...v1.12.0
[1.11.0]: https://github.com/0jonjo/calcpace/compare/v1.10.0...v1.11.0
[1.10.0]: https://github.com/0jonjo/calcpace/compare/v1.9.10...v1.10.0
[1.9.6]: https://github.com/0jonjo/calcpace/compare/v1.9.5...v1.9.6
[1.9.5]: https://github.com/0jonjo/calcpace/compare/v1.9.4...v1.9.5
[1.6.0]: https://github.com/0jonjo/calcpace/releases/tag/v1.6.0
