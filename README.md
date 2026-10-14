<p align="center"><img src="https://raw.githubusercontent.com/0jonjo/calcpace/main/docs/logo.svg" alt="calcpace logo" width="128"></p>

# Calcpace [![Gem Version](https://badge.fury.io/rb/calcpace.svg)](https://badge.fury.io/rb/calcpace)

A Ruby gem for runners: pace, time, and distance calculations, unit conversions, race predictions (including personalized ones), GPS track analysis with grade-adjusted pace, heat, humidity and altitude adjustments, age grading, VO2max estimation and norms, and training zones.

- **Built on published models:** Riegel, Cameron, Daniels & Gilbert, El Helou, Minetti, FRIEND and the 2025 age-grading tables. The guide names the source behind each number and says where the published data ends and an extrapolation begins.
- **Checked:** the single-line examples in this README and in the [usage guide](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md) run in the test suite against the real code.
- **No runtime dependencies.** Ruby >= 3.3.

> **See it in action:** [calcpace.app](https://calcpace.app) — free running calculators, race predictors and a training log in 16 languages, all powered by this gem. Also on Android: [Google Play](https://play.google.com/store/apps/details?id=app.calcpace.twa).

## Installation

```ruby
gem 'calcpace', '~> 2.1'
```

## Quick tour

```ruby
require 'calcpace'
calc = Calcpace.new

calc.clock_pace('01:00:00', 10)                          # => "00:06:00"
calc.predict_time_clock('5k', '00:27:12', 'marathon')    # => "04:20:52"
calc.calculate_penalty(temperature: 30, humidity: 90)[:total_penalty_percent]  # => 12.16
calc.race_splits('10k', target_time: '00:40:00', split_distance: '5k', strategy: :negative)  # => ["00:20:12", "00:40:00"]
calc.estimate_vo2max(10.0, '00:40:00')                   # => 51.9
calc.age_grade(10.0, '00:45:00', age: 55, sex: :male)[:age_grade_percent]  # => 68.9
calc.training_paces(50.0)[:threshold].fast_clock         # => "00:04:15"
```

## What's in it

Every method, with examples, is in the **[usage guide](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md)**:

| Area | What it does |
| --- | --- |
| [Basic calculations](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#basic-calculations) | Pace, time, distance and velocity, in seconds or `HH:MM:SS` |
| [Environmental adjustments](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#environmental-performance-adjustments) | Heat, humidity and altitude penalties, applied to a time or a prediction |
| [Unit](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#unit-conversions) and [pace conversions](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#pace-conversions) | 40+ conversions between distance and speed units; pace per km ↔ per mile |
| [Race pace & time](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#race-pace--time) | Any named race or plain distance |
| [Race splits](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#race-splits) | Even, negative or positive splits |
| [Race time predictions](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#race-time-predictions) | Riegel and Cameron |
| [Personalized predictions](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#personalized-predictions) | Tanda marathon from training volume, personal Riegel exponent |
| [GPS track analysis](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#gps-track-analysis) | Distance, elevation gain, per-km splits, grade-adjusted pace (Minetti) |
| [Age grading](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#age-grading-road-races) | 2025 road tables |
| [VO2max estimation](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#vo2max-estimation) | Daniels & Gilbert, FRIEND age/sex norms, effort and elevation context |
| [Training zones](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#training-zones) | Daniels paces, Karvonen and %HRmax zones, time in zones |
| [Lap analysis](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#lap-analysis) | Reads an interval session (reps, work and rest paces) from laps |
| [Stride & cadence](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#stride--cadence) | Stride length from pace and cadence, and back |
| [Fitness predictor](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#fitness-predictor-race-times-from-vo2max) | Race times from a VO2max |
| [Other utilities](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#other-utilities) and [errors](https://github.com/0jonjo/calcpace/blob/main/docs/USAGE.md#errors) | Helpers and the error classes |

## Testing

```bash
bundle exec rake
```

Requires Ruby >= 3.3.0. Tested with Ruby 3.3, 3.4, and 4.0.

## Contributing

Clone the repo and submit a pull request. Please include tests.

## License

[MIT License](https://opensource.org/licenses/MIT)
