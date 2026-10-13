<p align="center"><img src="https://raw.githubusercontent.com/0jonjo/calcpace/main/docs/logo.svg" alt="calcpace logo" width="128"></p>

# Calcpace [![Gem Version](https://badge.fury.io/rb/calcpace.svg)](https://badge.fury.io/rb/calcpace)

A Ruby gem for runners: pace, time, and distance calculations, unit conversions, race predictions (including personalized ones), GPS track analysis with grade-adjusted pace, heat, humidity and altitude adjustments, age grading, VO2max estimation and norms, and training zones.

- **Sourced:** every model names the paper or table it comes from (Riegel, Cameron, Daniels & Gilbert, El Helou, Minetti, FRIEND, the 2025 age-grading tables), and the guide says where the published data ends and an extrapolation begins.
- **Checked:** the examples in this README and in the [usage guide](docs/USAGE.md) run in the test suite, so a documented value is the value the code returns.
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

Every method, with examples, is in the **[usage guide](docs/USAGE.md)**:

| Area | What it does |
| --- | --- |
| [Basic calculations](docs/USAGE.md#basic-calculations) | Pace, time, distance and velocity, in seconds or `HH:MM:SS` |
| [Environmental adjustments](docs/USAGE.md#environmental-performance-adjustments) | Heat, humidity and altitude penalties, applied to a time or a prediction |
| [Unit](docs/USAGE.md#unit-conversions) and [pace conversions](docs/USAGE.md#pace-conversions) | 30+ units; min/km ↔ min/mi ↔ km/h |
| [Race pace & time](docs/USAGE.md#race-pace--time) | Any named race or plain distance |
| [Race splits](docs/USAGE.md#race-splits) | Even, negative or positive splits |
| [Race time predictions](docs/USAGE.md#race-time-predictions) | Riegel and Cameron |
| [Personalized predictions](docs/USAGE.md#personalized-predictions) | Tanda marathon from training volume, personal Riegel exponent |
| [GPS track analysis](docs/USAGE.md#gps-track-analysis) | Distance, elevation gain, per-km splits, grade-adjusted pace (Minetti) |
| [Age grading](docs/USAGE.md#age-grading-road-races) | 2025 road tables |
| [VO2max estimation](docs/USAGE.md#vo2max-estimation) | Daniels & Gilbert, FRIEND age/sex norms, effort and elevation context |
| [Training zones](docs/USAGE.md#training-zones) | Daniels paces, Karvonen and %HRmax zones, time in zones |
| [Lap analysis](docs/USAGE.md#lap-analysis) | Detects intervals and steady runs from laps |
| [Stride & cadence](docs/USAGE.md#stride--cadence) | Stride length from pace and cadence, and back |
| [Fitness predictor](docs/USAGE.md#fitness-predictor-race-times-from-vo2max) | Race times from a VO2max |
| [Other utilities](docs/USAGE.md#other-utilities) and [errors](docs/USAGE.md#errors) | Helpers and the error classes |

## Testing

```bash
bundle exec rake
```

Requires Ruby >= 3.3.0. Tested with Ruby 3.3, 3.4, and 4.0.

## Contributing

Clone the repo and submit a pull request. Please include tests.

## License

[MIT License](https://opensource.org/licenses/MIT)
