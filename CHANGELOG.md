# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.17.0] - 2026-09-05

### Added
- `time_in_zones(heartrate:, time:, zones:)` — splits a recorded heart-rate
  series into the seconds spent in each of the five zones returned by `hr_zones`
  or `hr_zones_from_max`, plus each zone's share of the counted time. Inputs are
  two plain arrays, so a Strava `heartrate`/`time` stream pair fits without
  translation and so does the same pair read out of a FIT file.

  A sample lasts until the next one, and the last sample inherits the previous
  delta so a series does not lose its final seconds. A sample with a nil or
  non-positive heart rate contributes nothing — its duration is dropped, never
  reassigned to a neighbour. Readings below zone 1 count as zone 1 and readings
  above zone 5 as zone 5: an `hr_max` that is a few beats wrong should distort
  the split, not make minutes of a run disappear.

  ```ruby
  zones = calc.hr_zones_from_max(hr_max: 190)

  in_zones = calc.time_in_zones(
    heartrate: [120, 120, 140, 140, 160],
    time:      [0, 60, 120, 180, 240],
    zones:     zones
  )

  in_zones.map(&:seconds)  # => [0, 120, 120, 60, 0]
  in_zones.map(&:share)    # => [0.0, 0.4, 0.4, 0.2, 0.0]
  ```

- `interval_structure(laps, unit: :km)` — new `LapAnalyzer` module. Detects a
  structured interval session in a watch's laps by **contrast**, never by a
  label: a lap is work when it covers at least 0.1 km and is at least 15% faster
  than every lap touching it. What comes before the first work lap is warm-up,
  what follows the last is cool-down, and what sits between two work laps is
  rest.

  ```ruby
  laps = [{ distance: 2.0, elapsed: 720 }] +
         ([{ distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 156 }] * 6) +
         [{ distance: 1.5, elapsed: 540 }]

  calc.interval_structure(laps)
  # => #<struct reps=6, work_distance=1.0, work_pace=252, rest_pace=390, rest_duration=156>
  ```

  It returns `nil` when the laps describe no structure — fewer than two work
  laps, or work laps more than ±25% away from their median distance, which is a
  fartlek or a hilly run rather than a set. Most runs are not intervals, and
  inventing reps out of ordinary pace variation would make every easy run look
  like a workout. A distance of `0` is a legal standing recovery, and makes
  `rest_pace` nil rather than infinite. `unit: :mi` converts both paces;
  distances stay in kilometres.

## [1.16.0] - 2026-09-05

### Added
- `stride_length(pace, cadence, unit: :km)` — metres per step from a pace (clock
  string or seconds per unit) and a cadence in steps per minute counting **both
  feet**; Strava's API reports cadence as one-leg RPM, so callers reading it from
  there must double it first.
- `cadence_for_stride(pace, stride, unit: :km)` — the inverse: the both-feet
  cadence in steps per minute that a given stride length implies at a given pace.

## [1.15.0] - 2026-08-30

### Added
- Every method that takes a race now accepts a **plain distance in kilometers**,
  not only one of the eight standard race names. Most races are not a 5K or a
  marathon, and a formula does not care what a distance is called:

  ```ruby
  calc.race_time_clock('05:00', 7.79)                        # => "00:38:57"
  calc.race_pace_clock('00:26:59', 7.79)                     # => "00:03:27"
  calc.predict_time_clock(7.79, '00:26:59', 'half_marathon') # => "01:17:34"
  calc.predict_time_clock('10k', '00:42:00', 15)             # => "01:04:33"
  calc.predict_time_clock(7.79, '00:26:59', 15)              # => "00:54:02"
  calc.predict_time_cameron_clock(7.79, '00:26:59', 'half_marathon') # => "01:13:44"
  calc.race_splits(7.79, target_time: '00:26:59', split_distance: '1k')
  # => ["00:03:28", "00:06:56", "00:10:23", "00:13:51", "00:17:19", "00:20:47", "00:24:15", "00:26:59"]
  ```

  Both ends of a prediction follow the same rule, so all four combinations work:
  name to name, name to number, number to name, number to number. The methods
  that reach a distance through `race_distance` inherit it: `race_time`,
  `race_pace`, their `_clock` variants, `predict_time`, `predict_pace`,
  `equivalent_performance`, the Cameron equivalents, the `_adjusted` variants,
  `race_splits`, and `race_times_from_vo2max`.

  A numeric **string** counts as a distance: `'7.79'` and `7.79` mean the same
  thing. This is not a new convention — `training_paces_from_race` and
  `predict_time_from_vo2max` have read numeric strings as distances since they
  were written, and `race_distance` was the one place that disagreed. A string
  that is not a number is still a race name, so `'7.79k'` remains
  `ArgumentError: Unknown race`. Only `Numeric` and `String` are read as
  distances; a Symbol is always a name, as in the two methods above.

  A numeric distance must be positive, and reports itself the way every other
  distance in the gem does:

  ```ruby
  calc.race_time(300, 0) # => Calcpace::NonPositiveInputError: Distance must be a positive number
  ```

  Before this release those calls raised `ArgumentError: Unknown race: 0`. The
  input was an error either way; only the class and the message changed.

### Breaking
- **A non-positive distance now raises `Calcpace::NonPositiveInputError`
  instead of `ArgumentError`.** Calls like `race_time(300, 0)` or
  `race_splits('0', ...)` used to fail with `ArgumentError: Unknown race: 0`,
  because `0` was not a race name; now `0` is read as a distance and rejected
  as one. `Calcpace::NonPositiveInputError` inherits from `Calcpace::Error`,
  **not** from `ArgumentError`, so a caller that wraps this library in
  `rescue ArgumentError` — a form field arriving as `"0"`, for example — will
  see the exception escape instead of being caught.
  The alternative was to make this one path raise `ArgumentError` for
  consistency with the old behaviour, which would have made the library
  inconsistent with itself: every other non-positive input in the gem already
  raises `NonPositiveInputError`. Wrapping in `rescue Calcpace::Error,
  ArgumentError` handles both this and any future version.

### Changed
- The "from and to must be different distances" guard in `predict_time` and
  `predict_time_cameron` no longer compares distances with `==`. Two distances
  now count as the same race when they differ by less than
  `PaceCalculator::SAME_DISTANCE_TOLERANCE_RATIO` (1e-9, relative), so a
  distance that only differs by floating-point noise still raises instead of
  returning a prediction of the same time back:

  ```ruby
  calc.predict_time(10.0, 2520, '10k')
  # => ArgumentError: From and to races must be different distances (both are 10.0km)
  ```

  The window is deliberately narrow: it absorbs representation noise and
  nothing else. `predict_time(10.0, 2520, 10.2)` is a legitimate 200 m
  extrapolation and still answers.

- Age grading matches a numeric distance to a standard within **2%**, up from
  0.5% (`AgeGrading::STANDARD_DISTANCE_TOLERANCE_RATIO`, previously an
  unnamed literal). GPS rarely reads a 5K as exactly 5.000 km, and 2% is the
  window calcpace.app already uses to decide a run "is a 5K" — the two used to
  disagree about the same run:

  ```ruby
  calc.age_grade_percent(5.0,    '00:25:00', age: 40, sex: :male) # => 51.9
  calc.age_grade_percent(5.0374, '00:25:00', age: 40, sex: :male) # => 51.9
  ```

  Nothing else about age grading changed, on purpose. A distance outside the
  window still raises, and that is the intended answer rather than a missing
  feature: the WMA 2023 tables publish a factor per *specific* distance, so
  there is no standard for 7.79 km to compare against, and interpolating one
  would produce a number with the look of an official standard and none of the
  authority.

  ```ruby
  calc.age_grade(7.79, '00:26:59', age: 36, sex: :male)
  # => ArgumentError: Unsupported distance 7.79km. Supported: 5.0, 10.0, 21.0975, 42.195 km
  ```

  Riegel and Cameron both degrade as the jump between distances grows — a
  marathon predicted from a 1 km time is arithmetic, not a forecast. This
  release adds no guard against that: the gem never warned about it for the
  standard race names either, and inventing a threshold now would be a new
  opinion, not a fix. The note is here and in the README so the caller can
  weigh it.

### Fixed
- Documentation only, no behavior change: several `@example` values in
  `PaceCalculator`, `RacePredictor` and `CameronPredictor`, and their
  counterparts in the README, had drifted from what the code returns — the
  worst of them by more than six minutes (`predict_time_cameron_clock` was
  documented as `'00:02:32'` where it returns `'00:04:15'`). Two `@example`
  lines also used `:5k`, which is not valid Ruby syntax, and now use `'5k'`.
- An adversarial review of this release found three more that the first pass
  had missed, including the README block for `equivalent_performance` — which
  contradicted the docstring corrected in this very release — and the main
  age-grading example, wrong in four of its eight fields. Every example was
  then executed and compared line by line, README and `@example` alike. The
  lesson was acted on rather than recorded: `test_documented_examples.rb` now
  executes every single-line example in the README and in the docstrings and
  compares it with what the code returns, so a drifted example fails the suite
  instead of reaching a reader. It pins two numbers — how many examples it
  finds and how many it actually compares — because a scanner that silently
  matches nothing would pass forever.

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

[Unreleased]: https://github.com/0jonjo/calcpace/compare/v1.16.0...HEAD
[1.16.0]: https://github.com/0jonjo/calcpace/compare/v1.15.0...v1.16.0
[1.15.0]: https://github.com/0jonjo/calcpace/compare/v1.14.0...v1.15.0
[1.14.0]: https://github.com/0jonjo/calcpace/compare/v1.13.0...v1.14.0
[1.13.0]: https://github.com/0jonjo/calcpace/compare/v1.12.1...v1.13.0
[1.12.0]: https://github.com/0jonjo/calcpace/compare/v1.11.0...v1.12.0
[1.11.0]: https://github.com/0jonjo/calcpace/compare/v1.10.0...v1.11.0
[1.10.0]: https://github.com/0jonjo/calcpace/compare/v1.9.10...v1.10.0
[1.9.6]: https://github.com/0jonjo/calcpace/compare/v1.9.5...v1.9.6
[1.9.5]: https://github.com/0jonjo/calcpace/compare/v1.9.4...v1.9.5
[1.6.0]: https://github.com/0jonjo/calcpace/releases/tag/v1.6.0
