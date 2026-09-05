# Calcpace [![Gem Version](https://badge.fury.io/rb/calcpace.svg)](https://badge.fury.io/rb/calcpace)

A Ruby gem for runners: pace, time, and distance calculations, unit conversions, race predictions, GPS track analysis, age grading, VO2max estimation, and training zones.

## Installation

```ruby
gem 'calcpace', '~> 1.12.0'
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
calc.time(210, 12)                  # => 2520   (pace × distance)
calc.distance(9660, 120)            # => 80.5   (velocity × time)

# Clocktime input/output (HH:MM:SS or MM:SS)
calc.clock_pace('01:00:00', 10)     # => "00:06:00"
calc.clock_time('00:05:31', 12.6)   # => "01:09:30"
calc.checked_distance('01:21:32', '00:06:27') # => 12.64
```

---

### Environmental Performance Adjustments

Adjust race performance based on heat and altitude. Calculations are based on scientific models
(Matthew Ely 2007 for heat, NCAA standards for altitude).

```ruby
# Calculate penalty for 25°C and 2000m altitude (Defaults to 60-min effort)
penalty = calc.calculate_penalty(temperature: 25, altitude: 2000)
# => {
#      total_penalty_percent: 8.62,
#      factors: { heat: 4.3, altitude: 4.32 }
#    }

# Fahrenheit support
calc.calculate_penalty(temperature: 80, temperature_unit: :f)
# => { total_penalty_percent: 5.03, ... }

# Adjust a 3:30 marathon time (12600s) for these conditions (High exposure penalty)
result = calc.adjust_time(12600, temperature: 25, altitude: 2000)
# => {
#      original_time: 12600,
#      adjusted_time: 15176.7,
#      adjusted_time_clock: "04:12:56",
#      penalty_percent: 20.45,
#      factors: { heat: 16.13, altitude: 4.32 }
#    }

# Predicted adjusted times (Riegel formula)
calc.predict_time_adjusted('5k', '00:20:00', '10k', temperature: 28)
# => { adjusted_time: 2599.74, adjusted_time_clock: "00:43:19", penalty_percent: 3.91, ... }

# Predicted adjusted times (Cameron formula)
calc.predict_time_cameron_adjusted('10k', '00:40:00', 'marathon', temperature: 80, temperature_unit: :f)
# => { adjusted_time: 11585.88, adjusted_time_clock: "03:13:05", penalty_percent: 14.18, ... }
```

---

### Unit Conversions

30+ units supported. String or symbol format:

```ruby
calc.convert(10, :km_to_mi)         # => 6.213711922...
calc.convert(10, 'mi to km')        # => 16.09344
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
calc.convert_pace(300, :km_to_mi)  # => "00:08:02"
```

All three take a `compact:` keyword for the display format a runner reads on a
screen, the same one `convert_to_clocktime` offers:

```ruby
calc.pace_km_to_mi('05:00', compact: true)         # => "8:02"
calc.pace_mi_to_km(480, compact: true)             # => "4:58"
calc.convert_pace('05:00', :km_to_mi, compact: true)  # => "8:02"
```

---

### Race Pace & Time

Every method that takes a race accepts either a standard race name or a plain
distance in kilometers — most races are not a 5K or a marathon.

```ruby
calc.race_time_clock('05:00', 'marathon')          # => "03:30:58"
calc.race_pace_clock('04:00:00', 'marathon')       # => "00:05:41"
calc.list_races  # => { '5k' => 5.0, '10k' => 10.0, 'half_marathon' => 21.0975, 'marathon' => 42.195, '100k' => 100.0, ... }

# Any distance, named or not — 7.79 km and '7.79' mean the same thing
calc.race_time_clock('05:00', 7.79)                # => "00:38:57"
calc.race_time_clock('05:00', '7.79')              # => "00:38:57"
calc.race_pace_clock('00:26:59', 7.79)             # => "00:03:27"
```

A distance must be positive (`Calcpace::NonPositiveInputError` otherwise), and
anything that is neither a number nor a known race name still raises
`ArgumentError` — `'7.79k'` is a typo, not a distance.

---

### Race Splits

```ruby
# Even pace — default
calc.race_splits('half_marathon', target_time: '01:30:00', split_distance: '5k')
# => ["00:21:20", "00:42:40", "01:03:59", "01:25:19", "01:30:00"]

# Strategies: :even (default), :negative (second half faster), :positive (first half faster)
calc.race_splits('10k', target_time: '00:40:00', split_distance: '5k', strategy: :negative)
# => ["00:20:48", "00:40:00"]

# The race may be a plain distance too; the last split is always the finish
calc.race_splits(7.79, target_time: '00:26:59', split_distance: '1k')
# => ["00:03:28", "00:06:56", "00:10:23", "00:13:51", "00:17:19", "00:20:47", "00:24:15", "00:26:59"]
```

---

### Race Time Predictions

**Riegel formula** (`T2 = T1 × (D2/D1)^1.06`):

```ruby
calc.predict_time_clock('5k', '00:20:00', 'marathon')   # => "03:11:49"
calc.predict_pace_clock('5k', '00:20:00', 'marathon')   # => "00:04:32"
calc.equivalent_performance('10k', '00:42:00', '5k')
# => { time: 1208.67, time_clock: "00:20:08", pace: 241.73, pace_clock: "00:04:01" }
```

**Cameron formula** (exponential correction — tends to be more conservative from short distances):

```ruby
calc.predict_time_cameron_clock('10k', '00:42:00', 'marathon')  # => "02:57:34"
calc.predict_pace_cameron_clock('10k', '00:42:00', 'marathon')  # => "00:04:12"
```

**Any distance, on either end.** Both formulas are arithmetic on two distances,
so neither end has to be a standard race:

```ruby
# From a 7.79 km club race in 26:59
calc.predict_time_clock(7.79, '00:26:59', 'half_marathon')          # => "01:17:34"
calc.predict_time_cameron_clock(7.79, '00:26:59', 'half_marathon')  # => "01:13:44"

# To an unnamed distance, and between two of them
calc.predict_time_clock('10k', '00:42:00', 15)    # => "01:04:33"
calc.predict_time_clock(7.79, '00:26:59', 15)     # => "00:54:02"

calc.equivalent_performance(7.79, '00:26:59', '10k')
# => { time: 2109.682710043339, time_clock: "00:35:09", pace: 210.96827100433387, pace_clock: "00:03:30" }
```

Predicting a distance from itself has no answer, so it raises — for a name, a
number, or one of each:

```ruby
calc.predict_time(10.0, 2520, '10k')
# => ArgumentError: From and to races must be different distances (both are 10.0km)
```

Both formulas were fitted around race distances and degrade as the jump grows:
a marathon predicted from a 1 km time is arithmetic, not a forecast. The gem
computes what you ask for and does not second-guess the gap — that judgement is
the caller's, and it always was, standard race names included.

---

### GPS Track Analysis

Accepts an array of hashes with `:lat`, `:lon`, and optionally `:ele` (metres) and `:time` (`Time`):

```ruby
points = [
  { lat: -23.5505, lon: -46.6333, ele: 760.0, time: Time.parse('2024-01-01 07:00:00') },
  { lat: -23.5510, lon: -46.6400, ele: 765.0, time: Time.parse('2024-01-01 07:05:00') },
  { lat: -23.5520, lon: -46.6480, ele: 758.0, time: Time.parse('2024-01-01 07:10:00') },
]

calc.haversine_distance(-23.5505, -46.6333, -23.5510, -46.6340)
# => 0.09045636644035066 (km)

calc.track_distance(points)  # => 1.51 (km)
calc.elevation_gain(points)  # => { gain: 5.0, loss: 7.0 }

calc.track_splits(points, 1.0)
# => [{ km: 1.0, elapsed: 415, pace: "06:55" },
#     { km: 1.51, elapsed: 600, pace: "06:04" }]

# Compact pace for display; :km and :elapsed are unchanged
calc.track_splits(points, 1.0, compact: true)
# => [{ km: 1.0, elapsed: 415, pace: "6:55" },
#     { km: 1.51, elapsed: 600, pace: "6:04" }]
```

The last entry is the partial split — the leftover distance after the last full
one, so its `:km` is the track total rather than a multiple of `split_km`.

Two things to know about `compact:` here. A split slower than an hour per unit
is where the formats stop differing by padding alone: the padded one keeps
counting minutes (`"66:33"`), as `track_splits` always has, while the compact
one rolls them into an hour field (`"1:06:33"`). And a track that steps
backwards in time — a watch resyncing its clock, a paused device, two segments
merged out of order — produces a negative split, reported with a leading minus
in both formats (`"-00:40"` / `"-0:40"`) rather than raising.

**Haversine formula** — great-circle distance on a sphere (R = 6,371 km). Accuracy: ~0.3% of GPS/WGS84. Best for running and cycling distances; not for geodetic surveying.

---

### Age Grading (Road Races)

Age grading compares race results across different ages and sexes by using
age factors and open standards.

```ruby
result = calc.age_grade(10.0, '00:45:00', age: 55, sex: :male)
# numeric distances also accepted in miles: calc.age_grade(6.21371, '00:45:00', age: 55, sex: :male, distance_unit: :mi)
# => {
#      age_grade_percent: 69.0,
#      category: "Local Class",
#      age_graded_time_seconds: 2278.26,
#      age_graded_time_clock: "00:37:58",
#      open_standard_seconds: 1571.0,
#      open_standard_clock: "00:26:11",
#      factor: 0.8438,
#      table_version: "WMA_2023_ONE_YEAR_FACTORS_V1"
#    }

calc.age_grade_percent(5.0, '00:22:30', age: 40, sex: :female) # => 65.2
calc.age_grade_label(65.2)                                      # => "Local Class"
```

Supported distances: 5K, 10K, half marathon, marathon.

A numeric distance within **2%** of one of those is graded as that standard —
a GPS watch rarely reads a 5K as exactly 5.000 km:

```ruby
calc.age_grade_percent(5.0,    '00:25:00', age: 40, sex: :male) # => 51.9
calc.age_grade_percent(5.0374, '00:25:00', age: 40, sex: :male) # => 51.9

calc.age_grade(7.79, '00:26:59', age: 36, sex: :male)
# => ArgumentError: Unsupported distance 7.79km. Supported: 5.0, 10.0, 21.0975, 42.195 km
```

That refusal is deliberate, and it is where age grading parts ways with the
predictors above. A prediction is a formula and works at any distance; an age
grade is a lookup in the WMA table, which publishes a factor per *specific*
distance. There is no world standard for 7.79 km, so there is no honest
percentage to return — interpolating one would produce a number with the look
of an official standard and none of the authority.

Age factors are based on WMA 2023 one-year age grading tables:
https://world-masters-athletics.org/documents/competition-rules/

Open standards used in `open_standard_seconds` / `open_standard_clock` are loaded
from the bundled WMA 2023 open standards dataset
(`lib/calcpace/data/wma_2023_open_standards.yml`).

Field meanings:
- `age_graded_time_clock`: your result after applying the WMA age factor (normalized performance time).
- `open_standard_clock`: the open standard reference time used to compute the percentage for that distance/sex.
- `age_grade_percent`: `(open_standard_seconds / age_graded_time_seconds) * 100`.

---

### VO2max Estimation

Estimate aerobic fitness from a race result using the **Daniels & Gilbert formula** (1979):

```ruby
calc.estimate_vo2max(10.0, '00:40:00')   # => 51.9 ml/kg/min
calc.estimate_vo2max(42.195, '03:30:00') # => 44.6
calc.estimate_vo2max(5.0, 2400)          # also accepts total seconds
calc.estimate_vo2max(6.21371, '00:40:00', distance_unit: :mi)  # => 51.9 (miles input)

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

*Thresholds based on Daniels, J. (2014). Daniels' Running Formula (3rd ed.), consistent with ACSM guidelines and McArdle, Katch & Katch (2015) Exercise Physiology.*

**Formula:**
```
velocity (m/min) = distance_m / time_min
VO2              = −4.60 + 0.182258·v + 0.000104·v²
%VO2max          = 0.8 + 0.1894393·e^(−0.012778·t) + 0.2989558·e^(−0.1932605·t)
VO2max           = VO2 / %VO2max
```

Accuracy: ±3–5 ml/kg/min vs. laboratory testing. Best with efforts between **5 and 60 minutes** at near-maximal pace.

#### Contextualized estimation

`estimate_detailed_vo2max` returns a richer result that accounts for elevation, heart rate, and formula reliability:

```ruby
# Mountain 10K: 200 m elevation gain, avg HR 172, max HR 190
result = calc.estimate_detailed_vo2max(
  10.0, '00:48:30',
  elevation_gain_m: 200,
  hr_avg: 172,
  hr_max: 190
)

result.value              # => 47.7  (corrected for 1.2 km of equivalent flat distance)
result.adjusted_distance_km # => 11.2  (10 km + 200 m × 6 flat-equivalent)
result.confidence         # => :high  (48 min is inside the 5–60 min optimal window)
result.sub_maximal        # => false  (172/190 = 90.5 % HRmax → maximal effort)

calc.vo2max_label(result.value)  # => "Good"

# Compare: same effort ignoring elevation → underestimates VO2max
flat = calc.estimate_detailed_vo2max(10.0, '00:48:30')
flat.value  # => 41.5

# Easy recovery run: sub-maximal effort flag + confidence downgrade
easy = calc.estimate_detailed_vo2max(10.0, '01:05:00', hr_avg: 135, hr_max: 190)
easy.sub_maximal  # => true   (135/190 = 71 % HRmax < 85 %)
easy.confidence   # => :low   (formula assumes race-pace effort)
easy.value        # => 29.3   (underestimates real aerobic capacity)
```

| `confidence` | Effort duration | Notes |
|---|---|---|
| `:high` | 5–60 min | Daniels & Gilbert optimal window |
| `:medium` | > 60–120 min | Muscular fatigue starts distorting the estimate |
| `:low` | < 5 min or > 120 min | Anaerobic / glycogen-depletion effects dominate |

> If `hr_avg > hr_max`, a `Calcpace::Error` is raised (physiologically impossible input).
> If you provide heart rate data, both `hr_avg` and `hr_max` must be present.
> `elevation_gain_m` must be zero or positive.

---

### Training Zones

Personalized training paces (Daniels' Running Formula) and Karvonen heart-rate zones:

```ruby
zones = calc.training_paces(50.0)
zones[:threshold].fast_clock   # => "00:04:15" per km
zones[:easy].slow_clock        # => "00:05:52" per km

calc.training_paces(50.0, unit: :mi)[:threshold].fast_clock  # => "00:06:51" per mile

calc.training_paces_from_race(10.0, '00:40:00')                # from a recent race result
calc.training_paces_from_race('5mile', '00:35:00', unit: :mi)  # race names work too
calc.training_paces_from_race(6.2, '00:40:00', distance_unit: :mi, unit: :mi)  # race distance in miles

calc.hr_zones(hr_max: 190, hr_rest: 55)
# => [#<struct zone=1, min_bpm=123, max_bpm=136>, ... zone=5, max_bpm=190]

calc.hr_zones_from_max(hr_max: 190)
# => [#<struct zone=1, min_bpm=95, max_bpm=114>, ... zone=5, max_bpm=190]
# %HRmax fallback — prefer hr_zones (Karvonen) when resting HR is known
```

| Zone | %VO2max | Purpose |
|------|---------|---------|
| Easy | 59–74% | Base building, recovery |
| Marathon | 75–84% | Marathon race pace |
| Threshold | 83–88% | Lactate threshold, tempo runs |
| Interval | 95–100% | VO2max development |
| Repetition | 105–110% | Speed and running economy |

Pace accuracy vs published VDOT tables: within a few seconds per km
(threshold matches exactly; easy band is a range heuristic).

`unit:` sets the unit of the returned pace bands; `distance_unit:` sets the unit of a
numeric race distance you pass in. Combining `distance_unit:` with a race name raises
`ArgumentError` — `'10k'` already carries its own distance. Mile bands are computed
natively (not converted from the km bands), so they can differ by ±1 s from
`pace_km_to_mi(km_band)`.

All mile factors derive from the exact international mile (1609.344 m), so distances,
pace bands, and age-grading tolerances agree to the metre.

#### Time in heart-rate zones

`time_in_zones` splits a recorded heart-rate series into the time spent in each zone.
It takes two plain arrays and the zones, so a Strava `heartrate`/`time` stream pair
fits without translation, and so does the same pair read out of a FIT file:

```ruby
zones = calc.hr_zones_from_max(hr_max: 190)

in_zones = calc.time_in_zones(
  heartrate: [120, 120, 140, 140, 160],
  time:      [0, 60, 120, 180, 240],
  zones:     zones
)

in_zones.map(&:seconds)  # => [0, 120, 120, 60, 0]
in_zones.map(&:share)    # => [0.0, 0.4, 0.4, 0.2, 0.0]
in_zones[1].zone         # => 2

# The same call in one line, if you would rather not name the zones
calc.time_in_zones(heartrate: [120, 140], time: [0, 60], zones: calc.hr_zones_from_max(hr_max: 190)).map(&:seconds)  # => [0, 60, 60, 0, 0]
calc.time_in_zones(heartrate: [120, 140], time: [0, 60], zones: calc.hr_zones_from_max(hr_max: 190)).map(&:share)    # => [0.0, 0.5, 0.5, 0.0, 0.0]
```

Five rows always come back, in zone order, zeros included — `seconds` whole, `share`
a fraction of the counted time with three decimals. The shares are whole thousandths
that add up to 1000 — rounded together, largest remainder first — so a bar chart
drawn from them fills its track (the Float sum may sit one ulp from 1.0).

**A sample lasts until the next one** (`time[i + 1] - time[i]`), and the last sample,
which has no next, is given the previous delta so a series does not lose its final
seconds; a single sample lasts 0 s.

That rule has a consequence worth knowing before trusting the numbers. **A pause is a
gap in `time`, and the whole gap is booked to the sample before it** — stop five
minutes at a café and those five minutes land in whatever zone the last beat before
the pause was in. There is no `max_gap` here to guess a cut-off with. If you have
Strava's `moving` stream, nil the heart rate of every paused sample before calling,
which hands them to the next rule.

A sample with a nil or non-positive heart rate contributes nothing: its duration is
**dropped, not reassigned**, because a dropout says nothing about which zone the
runner was in — so the counted time can be less than the wall clock, and the shares
are shares of what was counted.

Mismatched array lengths, a series that is not an array, a nil inside `time`, a
`time` that goes backwards, or a heart rate that is neither nil nor a number all
raise `Calcpace::Error`. Empty arrays return the five zero rows.

#### Which zone is this beat in?

`hr_zone_for` is the lookup `time_in_zones` uses, exposed on its own:

```ruby
calc.hr_zone_for(150, calc.hr_zones_from_max(hr_max: 190)).zone  # => 3
calc.hr_zone_for(114, calc.hr_zones_from_max(hr_max: 190)).zone  # => 2
calc.hr_zone_for(205, calc.hr_zones_from_max(hr_max: 190)).zone  # => 5
```

It returns the `HrZone`, or nil when the reading is nil or not positive — a sensor
dropout. Two rules are worth stating because a hand-rolled `between?` lookup gets
both wrong:

- **On a shared boundary the higher zone wins.** Zones are contiguous, so 114 bpm is
  both the top of Z1 and the bottom of Z2; it counts as Z2, the way a watch reads it.
- **Readings outside the range are clamped**, below Z1 to Z1 and above Z5 to Z5. A
  reading above `hr_max` means the `hr_max` is wrong, not that the beat did not
  happen — and an `hr_max` a few beats off is the most common thing an athlete
  carries around. Clamping keeps that a distortion of the split instead of making
  minutes of a run disappear.

---

### Lap Analysis

A watch records laps; it does not record intent. `interval_structure` reads the shape
of a session out of the laps themselves, by **contrast** — never by a label:

```ruby
# Warm-up, 6 x (1 km hard / 400 m jog), cool-down
laps = [{ distance: 2.0, elapsed: 720 }] +
       ([{ distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 156 }] * 6) +
       [{ distance: 1.5, elapsed: 495 }]

structure = calc.interval_structure(laps)
# => #<struct reps=6, work_distance=1.0, ... rest_duration=156>

structure.reps           # => 6
structure.work_distance  # => 1.0   (km, median rep)
structure.work_pace      # => 252   (seconds per km, distance-weighted)
structure.rest_pace      # => 390
structure.rest_duration  # => 156   (mean rest lap, seconds)
```

`to_a` gives all five at once, which is short enough to show whole. This is the
smallest session that has a structure — two reps and the jog between them:

```ruby
calc.interval_structure([{ distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 156 }, { distance: 1.0, elapsed: 252 }]).to_a  # => [2, 1.0, 252, 390, 156]

# unit: converts both paces; distances stay in kilometres
calc.interval_structure([{ distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 156 }, { distance: 1.0, elapsed: 252 }], unit: :mi).to_a  # => [2, 1.0, 406, 628, 156]
```

Laps are plain hashes of a distance in kilometres and an elapsed time in seconds —
what a Strava lap, a FIT lap and a hand-written array all reduce to. Distance `0` is
legal: it is a standing recovery, and it means an infinite pace.

A lap counts as **work** when it covers at least 0.1 km and is at least 15% faster
than every lap touching it. Everything before the first work lap is warm-up,
everything after the last is cool-down, and a lap between two work laps is rest. Two
work laps can never touch — each would have to be 0.85 of the other — so every pair
of reps has a recovery between it.

An **edge lap** — the first or the last — has only one neighbour, so contrast alone
is a free pass: a 5:30/km cool-down beats the 6:30/km jog it happens to touch and
walks in as an extra rep. So an edge lap is admitted only if it also agrees with the
reps found in the middle: within ±25% of their median distance, and no more than 10%
slower than their pace. When the interior found nothing there is nothing to agree
with, and the plain contrast rule stands — which is why the three-lap example above
still reads as two reps.

The method returns **nil** when the laps describe no structure, and most runs do not:

```ruby
# A steady 10 km, ten laps of 1 km within five seconds of each other
steady = [300, 298, 302, 296, 304, 300, 299, 301, 305, 295].map do |elapsed|
  { distance: 1.0, elapsed: elapsed }
end

calc.interval_structure(steady)  # => nil

# An easy 3 km with two red lights: fast next to a pause is not a rep
calc.interval_structure([{ distance: 1.0, elapsed: 300 }, { distance: 0.0, elapsed: 45 }, { distance: 1.0, elapsed: 300 }])  # => nil
```

Nil is returned when there are fewer than two work laps, when the work laps disagree
about distance — more than ±25% from their median makes it a fartlek or a hilly run,
which has fast laps but no set to report — or when **no work lap ever beat a finite
pace**. That last rule is what the red-light example trips: a zero-distance lap has
an infinite pace and everything is 15% faster than infinity, so without it every easy
run with a paused lap would come back as a set of reps.

`rest_pace` is nil when the recoveries covered no distance at all; a standing
recovery has a duration but no pace, and reporting infinity would be worse than
reporting nothing. A lap missing `:distance` or `:elapsed`, a negative distance, a
distance over 100 km (a caller who passed metres), or a non-positive elapsed time
raises `Calcpace::Error`; an empty array returns nil.

---

### Stride & Cadence

Pace, cadence and stride length are one identity, so any two of them give the third:

```ruby
calc.stride_length('05:00', 170)             # => 1.18
calc.stride_length('04:00', 180)             # => 1.39
calc.stride_length('08:02', 170, unit: :mi)  # => 1.18

calc.cadence_for_stride('05:00', 1.18)       # => 169.5
calc.cadence_for_stride('05:30', 1.15)       # => 158.1
```

`stride_length` returns metres per step (2 decimals); `cadence_for_stride` is its
inverse and returns steps per minute (1 decimal). Pace takes the same forms as
everywhere else — a clock string (`'05:00'`, `'00:05:00'`) or seconds per unit
(`300`) — and `unit:` says which unit that pace is per: `:km` (default) or `:mi`.
`8:02/mi` is `5:00/km` rounded down to the second (exactly 8:02.8), so the two strides
agree to the centimetre at this cadence.

Cadence is steps per minute counting **both feet** — the number a watch shows during a
run, typically 160–185 spm. Strava's API reports cadence as one-leg RPM, so a value
read from there must be doubled before it is passed in.

---

### Fitness Predictor (race times from VO2max)

The inverse of `estimate_vo2max`: what a given fitness is worth over a race.

```ruby
calc.predict_time_from_vo2max(50, '5k')             # => 1196.02 (seconds)
calc.predict_time_from_vo2max_clock(50, 'marathon') # => "03:10:39"

calc.predict_time_from_vo2max(50, 10.0)                          # numeric distance in km
calc.predict_time_from_vo2max_clock(50, 6.2, distance_unit: :mi) # => "00:41:13"

calc.race_times_from_vo2max(50)['10k']
# => { time: 2479.6, time_clock: "00:41:19", pace: 247.96, pace_clock: "00:04:07" }

calc.race_times_from_vo2max(50, races: %w[5k 10mile], unit: :mi)['5k']
# => { time: 1196.02, time_clock: "00:19:56", pace: 384.96, pace_clock: "00:06:24" }
```

`race_times_from_vo2max` returns the whole table in one call — default races are
`5k`, `10k`, `half_marathon`, and `marathon`, and `unit:` sets the pace unit. In
`predict_time_from_vo2max`, `distance_unit:` sets the unit of a numeric distance;
combining it with a race name raises `ArgumentError`, as elsewhere in the gem.

The Daniels & Gilbert curve has no closed-form inverse, so the time is found by
bisection — which makes the round trip exact:

```ruby
calc.estimate_vo2max(5.0, calc.predict_time_from_vo2max(50, '5k')) # => 50.0
```

Predictions match Daniels' published VDOT table within a few seconds for the shorter
races and about a minute for the marathon. VO2max values outside 10–100 ml/kg/min
raise `ArgumentError` — beyond that range the model stops describing running.

---

### Other Utilities

```ruby
calc.convert_to_seconds('01:00:00')  # => 3600
calc.convert_to_clocktime(3600)      # => "01:00:00"
calc.check_time('01:00:00')          # => nil (valid)
```

`convert_to_clocktime` takes a `compact:` keyword for the format a runner reads
on a screen — no zero hour, no leading zero on the most significant component:

```ruby
calc.convert_to_clocktime(292, compact: true)      # => "4:52"
calc.convert_to_clocktime(45, compact: true)       # => "0:45"
calc.convert_to_clocktime(5025, compact: true)     # => "1:23:45"
calc.convert_to_clocktime(100_000, compact: true)  # => "27:46:40"
```

Past 24 hours the compact format keeps counting hours, where the padded one
prefixes a day count (`"1 03:46:40"`). Fractional seconds truncate in both.
A negative number of seconds raises `Calcpace::NonPositiveInputError`; zero is a
valid duration (`"00:00:00"` / `"0:00"`).

The same `compact:` keyword is accepted by `convert_pace`, `pace_km_to_mi`,
`pace_mi_to_km`, and `track_splits`. It always defaults to `false`, so every
call without it returns exactly what it returned before.

---

### Errors

All errors inherit from `Calcpace::Error`:

- `Calcpace::NonPositiveInputError` — numeric input is zero or negative
- `Calcpace::InvalidTimeFormatError` — time string not in `HH:MM:SS` or `MM:SS` format
- `Calcpace::UnsupportedUnitError` — unknown conversion (`convert`) or unknown
  `unit:` / `distance_unit:` keyword

Argument validation that is not about units or numbers raises a plain `ArgumentError`:
unknown race names, unsupported age-grading distances, and invalid `age` / `sex` values.

---

### Testing

```bash
bundle exec rake
```

Requires Ruby >= 3.2.0. Tested with Ruby 3.2, 3.3, 3.4, and 4.0.

## Contributing

Clone the repo and submit a pull request. Please include tests.

## License

[MIT License](https://opensource.org/licenses/MIT)
