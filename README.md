# Calcpace [![Gem Version](https://d25lcipzij17d.cloudfront.net/badge.svg?id=rb&r=r&ts=1683906897&type=6e&v=1.9.3&x2=0)](https://badge.fury.io/rb/calcpace)

A Ruby gem for running and cycling calculations: pace, time, distance, unit conversions, race predictions, GPS track analysis, and VO2max estimation.

## Installation

```ruby
gem 'calcpace', '~> 1.9'
```

## Usage

```ruby
require 'calcpace'
calc = Calcpace.new
```

---

### Basic Calculations

```ruby
calc.velocity(3625, 12275)          # => 3.386  (distance / time)
calc.pace(3665, 12)                 # => 305.4  (time / distance)
calc.time(210, 12)                  # => 2520.0 (pace × distance)
calc.distance(9660, 120)            # => 80.5   (velocity × time)

# Clocktime input/output (HH:MM:SS or MM:SS)
calc.clock_pace('01:00:00', 10)     # => "00:06:00"
calc.clock_time('00:05:31', 12.6)   # => "01:09:30"
calc.checked_distance('01:21:32', '00:06:27') # => 12.64
```

---

### Unit Conversions

30+ units supported. String or symbol format:

```ruby
calc.convert(10, :km_to_mi)         # => 6.21371
calc.convert(10, 'mi to km')        # => 16.0934
calc.convert(1, :m_s_to_km_h)       # => 3.6

# Chain conversions
calc.convert_chain(1, [:km_to_mi, :mi_to_feet])  # => 3280.84
```

See all units: `calc.list_all`, `calc.list_distance`, `calc.list_speed`.

---

### Pace Conversions

```ruby
calc.pace_km_to_mi('05:00')   # => "00:08:02"
calc.pace_mi_to_km('08:00')   # => "00:04:58"
```

---

### Race Pace & Time

```ruby
calc.race_time_clock('05:00', 'marathon')          # => "03:30:58"
calc.race_pace_clock('04:00:00', 'marathon')       # => "00:05:41"
calc.list_races  # => { '5k' => 5.0, '10k' => 10.0, 'half_marathon' => 21.0975, 'marathon' => 42.195, '100k' => 100.0, ... }
```

---

### Race Splits

```ruby
# Even pace — default
calc.race_splits('half_marathon', target_time: '01:30:00', split_distance: '5k')
# => ["00:21:20", "00:42:40", "01:03:59", "01:25:19", "01:30:00"]

# Strategies: :even (default), :negative (second half faster), :positive (first half faster)
calc.race_splits('10k', target_time: '00:40:00', split_distance: '5k', strategy: :negative)
# => ["00:20:48", "00:40:00"]
```

---

### Race Time Predictions

**Riegel formula** (`T2 = T1 × (D2/D1)^1.06`):

```ruby
calc.predict_time_clock('5k', '00:20:00', 'marathon')   # => "03:11:49"
calc.predict_pace_clock('5k', '00:20:00', 'marathon')   # => "00:04:32"
calc.equivalent_performance('10k', '00:42:00', '5k')
# => { time: 1209.0, time_clock: "00:20:09", pace: 241.8, pace_clock: "00:04:02" }
```

**Cameron formula** (exponential correction — tends to be more conservative from short distances):

```ruby
calc.predict_time_cameron_clock('10k', '00:42:00', 'marathon')  # => "02:57:46"
calc.predict_pace_cameron_clock('10k', '00:42:00', 'marathon')  # => "00:04:13"
```

---

### GPS Track Analysis

Accepts an array of hashes with `:lat`, `:lon`, and optionally `:ele` (metres) and `:time` (`Time`):

```ruby
points = [
  { lat: -23.5505, lon: -46.6333, ele: 760.0, time: Time.parse('2024-01-01 07:00:00') },
  { lat: -23.5510, lon: -46.6400, ele: 765.0, time: Time.parse('2024-01-01 07:05:00') },
  { lat: -23.5520, lon: -46.6480, ele: 758.0, time: Time.parse('2024-01-01 07:10:00') },
]

calc.haversine_distance(-23.5505, -46.6333, -23.5510, -46.6340)  # => 0.089 km
calc.track_distance(points)    # => 0.87 km
calc.elevation_gain(points)    # => { gain: 5.0, loss: 7.0 }
calc.track_splits(points, 1.0) # => [{ km: 1, elapsed: 312, pace: "05:12" }, ...]
```

**Haversine formula** — great-circle distance on a sphere (R = 6,371 km). Accuracy: ~0.3% of GPS/WGS84. Best for running and cycling distances; not for geodetic surveying.

---

### VO2max Estimation

Estimate aerobic fitness from a race result using the **Daniels & Gilbert formula** (1979):

```ruby
calc.estimate_vo2max(10.0, '00:40:00')   # => 51.9 ml/kg/min
calc.estimate_vo2max(42.195, '03:30:00') # => 44.8
calc.estimate_vo2max(5.0, 2400)          # also accepts total seconds

calc.vo2max_label(51.9)  # => "Very Good"
```

| VO2max (ml/kg/min) | Level     |
|--------------------|-----------|
| ≥ 70               | Elite     |
| 60–69              | Excellent |
| 50–59              | Very Good |
| 40–49              | Good      |
| 30–39              | Fair      |
| < 30               | Beginner  |

**Formula:**
```
velocity (m/min) = distance_m / time_min
VO2              = −4.60 + 0.182258·v + 0.000104·v²
%VO2max          = 0.8 + 0.1894393·e^(−0.012778·t) + 0.2989558·e^(−0.1932605·t)
VO2max           = VO2 / %VO2max
```

Accuracy: ±3–5 ml/kg/min vs. laboratory testing. Best with efforts between **5 and 60 minutes** at near-maximal pace.

---

### Other Utilities

```ruby
calc.convert_to_seconds('01:00:00')  # => 3600
calc.convert_to_clocktime(3600)      # => "01:00:00"
calc.check_time('01:00:00')          # => nil (valid)
```

---

### Errors

All errors inherit from `Calcpace::Error`:

- `Calcpace::NonPositiveInputError` — numeric input is zero or negative
- `Calcpace::InvalidTimeFormatError` — time string not in `HH:MM:SS` or `MM:SS` format

---

### Testing

```bash
bundle exec rake
```

Requires Ruby >= 3.2.0.

## Contributing

Clone the repo and submit a pull request. Please include tests.

## License

[MIT License](https://opensource.org/licenses/MIT)
