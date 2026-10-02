# Calcpace [![Gem Version](https://badge.fury.io/rb/calcpace.svg)](https://badge.fury.io/rb/calcpace)

A Ruby gem for runners: pace, time, and distance calculations, unit conversions, race predictions (including personalized ones), GPS track analysis with grade-adjusted pace, heat, humidity and altitude adjustments, age grading, VO2max estimation and norms, and training zones.

> **See it in action:** [calcpace.app](https://calcpace.app) — free running calculators, race predictors and a training log, all powered by this gem.

## Installation

```ruby
gem 'calcpace', '~> 2.0'
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

# Clocktime input/output (HH:MM:SS or MM:SS; seconds below 60, and minutes too when hours are given)
calc.clock_pace('01:00:00', 10)     # => "00:06:00"
calc.clock_time('00:05:31', 12.6)   # => "01:09:30"
calc.checked_distance('01:21:32', '00:06:27') # => 12.64
```

---

### Environmental Performance Adjustments

Adjust race performance based on heat, humidity and altitude. Calculations are based on scientific models
(El Helou et al. 2012 and Ely et al. 2007 for heat, the Australian Bureau of Meteorology's
simplified WBGT for humidity, NCAA standards for altitude).

- **Altitude**: no penalty up to 300 m, then a linear ramp to the first NCAA point
  (914.4 m → 1.41%), the NCAA table up to 2438.4 m (5.90%), and an extrapolated
  curve beyond it (3000 m → 7.92%, 3500 m → 9.97%, 4000 m → 12.2%, capped there).
  São Paulo (760 m) gets ~1.06%.
- **Heat**: a 60-minute baseline `4.3 · ((T − 15) / 10)^1.5` (0% at 15 °C,
  1.52% at 20 °C, 4.3% at 25 °C, 7.9% at 30 °C; extrapolated to 12.16% at
  35 °C and capped there, so 35–40 °C and hotter all read like 35 °C), stored
  as points every 2.5 °C, then
  scaled by effort duration: 0.5× up to 30 min, 1.0× at 60 min, 1.76× at 3 h,
  2.81× at 4 h and beyond (linear in between, so 1.38× at 2 h). The exponent
  and the 3 h / 4 h points are fitted to El Helou et al. (2012, Table S3: eight
  finisher groups, 2:41–4:54, time penalty against 15 °C at 20 and 25 °C,
  which grows ~2.8× from 20 to 25 °C in every group); the derivation table is
  in `lib/calcpace/data/environmental_factors.yml`. The 25 °C / 60-minute
  anchor (4.3%) and the 30/60-minute factors have no direct published source.
- **Humidity** (optional): pass `humidity:` (relative humidity, %) or
  `dew_point:` (in `temperature_unit`). Without either, the heat curve assumes
  50% humidity. With one, the temperature is replaced by the effective
  temperature that has the same simplified WBGT (`0.567·Ta + 0.393·e + 3.94`)
  at 50% humidity, and `factors` reports it as `:effective_temperature_celsius`.

| Heat penalty (%) | 20 min | 60 min | 120 min | 180 min | 240 min | 300 min |
| --- | --- | --- | --- | --- | --- | --- |
| 20 °C | 0.76 | 1.52 | 2.1 | 2.68 | 4.27 | 4.27 |
| 25 °C | 2.15 | 4.3 | 5.93 | 7.57 | 12.08 | 12.08 |
| 30 °C | 3.95 | 7.9 | 10.9 | 13.9 | 22.2 | 22.2 |
| 35 °C | 6.08 | 12.16 | 16.78 | 21.4 | 34.17 | 34.17 |
| 40 °C | 6.08 | 12.16 | 16.78 | 21.4 | 34.17 | 34.17 |

| 30 °C at | Effective temperature | 60 min | 4 h |
| --- | --- | --- | --- |
| 30% RH | 26.69 °C | 5.46% | 15.34% |
| 50% RH (= no humidity) | 30.0 °C | 7.9% | 22.2% |
| 70% RH | 33.07 °C | 10.46% | 29.39% |
| 90% RH | 35.94 °C (capped at 35 °C) | 12.16% | 34.17% |

Above ~25 °C the numbers are extrapolations of the fitted curve: the marathon
studies behind it have no data there (El Helou's hottest race was 25.2 °C). The
cap at 35 °C is a deliberate choice for the same reason: the uncapped curve gave
47.77% for 4 h at 40 °C.

```ruby
# Calculate penalty for 25°C and 2000m altitude (Defaults to 60-min effort)
penalty = calc.calculate_penalty(temperature: 25, altitude: 2000)
# => {
#      total_penalty_percent: 8.62,
#      factors: { heat: 4.3, altitude: 4.32 }
#    }

# Fahrenheit support
calc.calculate_penalty(temperature: 80, temperature_unit: :f)
# => { total_penalty_percent: 5.44, ... }

# Humidity: 30 °C at 90% hits like 35.94 °C at 50% (which reads like the 35 °C cap)
calc.calculate_penalty(temperature: 30, humidity: 90)[:total_penalty_percent]  # => 12.16
calc.calculate_penalty(temperature: 30, humidity: 90)[:factors][:effective_temperature_celsius]  # => 35.94
calc.calculate_penalty(temperature: 86, dew_point: 77, temperature_unit: :f)[:total_penalty_percent]  # => 11.07

# Adjust a 3:30 marathon time (12600s) for these conditions (High exposure penalty)
result = calc.adjust_time(12600, temperature: 25, altitude: 2000)
# => {
#      original_time: 12600,
#      adjusted_time: 14382.9,
#      adjusted_time_clock: "03:59:42",
#      penalty_percent: 14.15,
#      factors: { heat: 9.83, altitude: 4.32 }
#    }

# Predicted adjusted times (Riegel formula)
calc.predict_time_adjusted('5k', '00:20:00', '10k', temperature: 28)
# => { adjusted_time: 2613.0, adjusted_time_clock: "00:43:33", penalty_percent: 4.44, ... }

# Predicted adjusted times (Cameron formula)
calc.predict_time_cameron_adjusted('10k', '00:40:00', 'marathon', temperature: 80, temperature_unit: :f)
# => { adjusted_time: 12400.47, adjusted_time_clock: "03:26:40", penalty_percent: 10.28, ... }
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
# :negative runs the first half 1% slower than average pace and the second half 1% faster;
# :positive is the mirror image. A 3:00:00 marathon splits 1:30:54 + 1:29:06 (:negative).
calc.race_splits('10k', target_time: '00:40:00', split_distance: '5k', strategy: :negative)
# => ["00:20:12", "00:40:00"]

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
# => { time: 1208.6727903498331, time_clock: "00:20:08", pace: 241.73455806996662, pace_clock: "00:04:01" }
```

**Cameron formula** (Dave Cameron's velocity-ratio model, fitted to world bests from
800 m to the marathon — more conservative than Riegel when predicting the marathon
from shorter races):

`T2 = T1 × (D2/D1) × f(D1)/f(D2)`, with `f(d) = 13.49681 − 0.000030363·d + 835.7114 / d^0.7905`
and `d` in metres (distances are still passed in km or as race names).
Both distances must be at most `CameronPredictor::CAMERON_MAX_DISTANCE_KM` (100 km):
the model is fitted up to the marathon and breaks down far beyond it, so longer
distances raise `ArgumentError`.

```ruby
calc.predict_time_cameron_clock('10k', '00:42:00', 'marathon')  # => "03:16:46"
calc.predict_pace_cameron_clock('10k', '00:42:00', 'marathon')  # => "00:04:39"
```

**Any distance, on either end.** Both formulas are arithmetic on two distances,
so neither end has to be a standard race:

```ruby
# From a 7.79 km club race in 26:59
calc.predict_time_clock(7.79, '00:26:59', 'half_marathon')          # => "01:17:34"
calc.predict_time_cameron_clock(7.79, '00:26:59', 'half_marathon')  # => "01:17:26"

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

### Personalized Predictions

**Marathon from training volume** — Tanda (2011), no race result needed. The
inputs are the mean weekly distance and the mean training pace over the 8 weeks
ending one week before the race:

```ruby
calc.predict_marathon_from_training(weekly_distance: 60, training_pace: '05:00')
# => { time: 11981.88, time_clock: "03:19:41", pace: 283.96, pace_clock: "00:04:43",
#      within_validated_range: true, out_of_range: [] }

calc.predict_marathon_from_training(weekly_distance: 40, training_pace: '05:30')
# => { time: 13158.72, time_clock: "03:39:18", pace: 311.86, pace_clock: "00:05:11",
#      within_validated_range: false, out_of_range: [:weekly_distance, :marathon_time] }

# unit: :mi — weekly miles, pace per mile in and out
calc.predict_marathon_from_training(weekly_distance: 25, training_pace: '08:00', unit: :mi)[:pace_clock] # => "00:07:53"
```

The equation is `Pm = 17.1 + 140.0 · exp(−0.0053 · K) + 0.55 · P` (Pm marathon
pace in s/km, K km/week, P s/km). Training pace is the plain average of every
run — total time over total distance, warm-ups and easy days included — not the
pace of the hard sessions. The paper reports a standard error of about 4 minutes.
`weekly_distance` may be a number or a numeric string (`'60'`); `training_pace`
is seconds or an `MM:SS` / `HH:MM:SS` string.

It was fitted on 22 experienced runners (21 men) and 46 marathons, so it is only
validated inside that sample: 40.4–110.7 km/week, training pace 253.3–330.6 s/km (4:13–5:30/km),
finish 2:47–3:36. Outside it the prediction is still returned, and
`out_of_range` names what fell outside (`:weekly_distance`, `:training_pace`,
`:marathon_time`) — a warning, not an error. A low-volume runner at an easy pace
will usually see all three.

> G. Tanda, "Prediction of marathon performance time on the basis of training
> indices", *Journal of Human Sport and Exercise* 6(3):511–520, 2011.
> doi:10.4100/jhse.2011.63.05

**Personal Riegel exponent** — fit the fatigue factor to two of your own races
instead of the population 1.06:

```ruby
calc.riegel_exponent('10k', '00:45:00', 'half_marathon', '01:42:00') # => 1.0961

calc.predict_time_personal('10k', '00:45:00', 'half_marathon', '01:42:00', 'marathon')
# => { time: 13083.04, time_clock: "03:38:03", exponent: 1.0961, raw_exponent: 1.0961, clamped: false }
```

The standard Riegel gives 3:32:39 from that half and 3:27:00 from that 10K; this
runner fades more than average, and the personal exponent says so.

When the target lies outside the two races, the prediction extrapolates from
whichever race is closer to it (in log-distance), with the exponent clamped to
1.01–1.20:

```ruby
calc.predict_time_personal('5k', '00:20:00', '10k', '00:50:00', 'half_marathon')
# => { time: 7348.5, time_clock: "02:02:28", exponent: 1.2, raw_exponent: 1.3219, clamped: true }
```

When the target lies between them, it interpolates along the curve through both
performances with the raw exponent, never clamped: the runner's own data
already brackets the answer, and the result does not depend on which race comes
first.

```ruby
calc.predict_time_personal(5, 1200, 20, 3000, 10)[:time] # => 1897.37
calc.predict_time_personal(20, 3000, 5, 1200, 10)[:time] # => 1897.37
```

An exponent outside that range — or `clamped: true` — usually means one of the
two races was not an all-out effort, or was run on a course or day that does
not compare with the other — the raw exponent in an interpolation
(0.661 above) is worth the same suspicion. Both races may be names or distances
in km; two races at the same distance, or a target equal to one of them, raise
`ArgumentError`. Times are seconds or `HH:MM:SS` / `MM:SS` strings; anything
else raises `Calcpace::InvalidTimeFormatError`.

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

#### Grade-adjusted pace (GAP)

The flat-ground pace that costs the same energy as a pace run on a slope, from
the energy cost of running on gradients measured by **Minetti et al. (2002)**.
The grade is a fraction (rise over horizontal distance): `0.05` is 5% uphill,
`-0.05` is 5% downhill.

```ruby
calc.grade_adjustment_factor(0.1)   # => 1.6578372222222222  (a metre at +10% ≈ 1.66 flat metres)
calc.grade_adjustment_factor(-0.1)  # => 0.5976961111111111

calc.grade_adjusted_pace(360, 0.1)                       # => 217.1503903847952 (s/km)
calc.grade_adjusted_pace_clock('06:00', 0.1)             # => "00:03:37"
calc.grade_adjusted_pace_clock('06:00', 0.1, compact: true)  # => "3:37"
calc.grade_adjusted_pace(480, 0.05, unit: :mi)           # => 368.82127811700303 (s/mi)

# Per-split GAP for a GPS track: the track_splits fields plus :gap
calc.track_grade_adjusted_splits(points, 1.0)
# => [{ km: 1.0, elapsed: 415, pace: "06:55", gap: "06:50" },
#     { km: 1.51, elapsed: 600, pace: "06:04", gap: "06:21" }]
```

| Grade | −10% | −5% | 0% | +5% | +10% |
|-------|------|-----|----|-----|------|
| Factor | 0.598 | 0.763 | 1.000 | 1.301 | 1.658 |

**Formula** (J·kg⁻¹·m⁻¹, R² = 0.999):
```
Cr(i)  = 155.4·i⁵ − 30.4·i⁴ − 43.3·i³ + 46.3·i² + 19.5·i + 3.6
factor = Cr(i) / Cr(0)
GAP    = pace / factor
```

- Grades are clamped to **±45%**, the range Minetti et al. measured; nothing
  is extrapolated beyond it. Running is cheapest near −20% and gets dearer
  again on steeper descents.
- It is a metabolic model: it does not see the muscular cost of long descents
  or technical terrain, and field models fitted to heart rate (Strava's, for
  instance) are gentler on steep climbs.
- `track_grade_adjusted_splits` leaves `track_splits` untouched: it returns the
  same `:km`, `:elapsed` and `:pace` with `:gap` added (formatted like `:pace`,
  `compact:` applies to both). GPS elevation is noisy, so grades are measured
  over **grade segments of at least 100 m** of horizontal distance — read
  between fixes a metre apart, ±2 m of jitter would be a ±400% grade. A short
  leftover at the end of a stretch joins the segment before it. Stretches
  between points without `:ele` (or with a NaN/infinite one) count as flat,
  so a track with no elevation has `:gap` equal to `:pace`; so does a stretch
  with elevation shorter than 100 m that has no full segment before it to
  join (between missing fixes, or a whole track that short).
- Track distances are horizontal (Haversine), and the factor is applied to
  them without the √(1 + grade²) slope-length correction — 0.5% at 10%.
- `estimate_detailed_vo2max` keeps its own flat elevation heuristic (100 m of
  gain = 600 m of flat), so its numbers do not change.

*Minetti, A. E., Moia, C., Roi, G. S., Susta, D., & Ferretti, G. (2002). Energy cost of walking and running at extreme uphill and downhill slopes. Journal of Applied Physiology, 93(3), 1039–1046. https://doi.org/10.1152/japplphysiol.01177.2001*

---

### Age Grading (Road Races)

Age grading compares race results across different ages and sexes by using
age factors and open standards.

```ruby
result = calc.age_grade(10.0, '00:45:00', age: 55, sex: :male)
# numeric distances also accepted in miles: calc.age_grade(6.21371, '00:45:00', age: 55, sex: :male, distance_unit: :mi)
# => {
#      age_grade_percent: 68.9,
#      category: "Local Class",
#      age_graded_time_seconds: 2297.97,
#      age_graded_time_clock: "00:38:17",
#      open_standard_seconds: 1584.0,
#      open_standard_clock: "00:26:24",
#      factor: 0.8511,
#      table_version: "MLDR_2025_ROAD_ONE_YEAR_FACTORS_V1"
#    }

calc.age_grade_percent(5.0, '00:22:30', age: 40, sex: :female) # => 65.0
calc.age_grade_label(65.0)                                      # => "Local Class"
```

`category` (and `age_grade_label`) returns one of:

| Age grade | Category |
| --- | --- |
| 100%+ | Approximate World Record Level |
| 90–99.9% | World Class |
| 80–89.9% | National Class |
| 70–79.9% | Regional Class |
| 60–69.9% | Local Class |
| 50–59.9% | Intermediate |
| 40–49.9% | Recreational |
| below 40% | Active Beginner |

The Alan Jones road tables are numeric age factors and open
standards only — they define no categories at all. The bands from Local Class
(60%) upward follow the USATF Masters / National Masters News convention; the
three bands below 60% are calcpace's own extension — most recreational
runners land there, and one catch-all label for everybody under 60% tells
them nothing.

The bands apply to the percentage as reported by `age_grade`, rounded to one
decimal, so calling `age_grade_label` directly on an unrounded value can land
one band lower at an edge.

Supported distances: 5K, 10K, half marathon, marathon.

A numeric distance within **2%** of one of those is graded as that standard —
a GPS watch rarely reads a 5K as exactly 5.000 km:

```ruby
calc.age_grade_percent(5.0,    '00:25:00', age: 40, sex: :male) # => 54.1
calc.age_grade_percent(5.0374, '00:25:00', age: 40, sex: :male) # => 54.1

calc.age_grade(7.79, '00:26:59', age: 36, sex: :male)
# => ArgumentError: Unsupported distance 7.79km. Supported: 5.0, 10.0, 21.0975, 42.195 km
```

That refusal is deliberate, and it is where age grading parts ways with the
predictors above. A prediction is a formula and works at any distance; an age
grade is a lookup in the road table, which publishes a factor per *specific*
distance. There is no world standard for 7.79 km, so there is no honest
percentage to return — interpolating one would produce a number with the look
of an official standard and none of the authority.

Age factors and open standards come from Alan Jones' **2025 road** age-grading
tables, approved on 2025-01-10 by the USATF Masters Long Distance Running
Council — the standard for road races, the same tables behind Howard Grubb's
MLDR road calculator. The source spreadsheets are `MaleRoadStd2025.xlsx` and
`FemaleRoadStd2025.xlsx`, linked here at the commit the bundled data was
taken from:
https://github.com/AlanLyttonJones/Age-Grade-Tables/tree/4aac6737cb9f216c90a0a610355667cd3d921c61/2025%20Files
The bundled data has one factor per year of age from 18 to 100 (older ages use
the age-100 factor) and lives in `lib/calcpace/data/mldr_2025_road.yml` (factors)
and `lib/calcpace/data/mldr_2025_road_open_standards.yml` (open standards and
category labels).

| Distance | Open standard (men) | Open standard (women) |
| --- | --- | --- |
| 5K | 12:49 | 13:54 |
| 10K | 26:24 | 28:46 |
| Half marathon | 57:31 | 1:02:52 |
| Marathon | 2:00:35 | 2:09:56 |

Field meanings:
- `age_graded_time_clock`: your result after applying the age factor (normalized performance time).
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

#### By age and sex

The fixed thresholds above are the same for everyone. Give `vo2max_label` an
age and a sex and it reads the value against people of the same sex and age
decade instead, using the **FRIEND registry** percentiles of VO2max measured on
a treadmill (Kaminsky, Arena & Myers, 2015):

```ruby
calc.vo2max_label(45)                         # => "Good"  (fixed thresholds, unchanged)
calc.vo2max_label(45, age: 25, sex: :male)    # => "Fair"
calc.vo2max_label(45, age: 60, sex: :male)    # => "Elite"
calc.vo2max_label(45, age: 25, sex: :female)  # => "Very Good"
calc.vo2max_label(45, age: 60, sex: :female)  # => "Elite"

calc.vo2max_percentile(45, age: 25, sex: :male)    # => 40.5
calc.vo2max_percentile(45, age: 25, sex: :female)  # => 75.7
calc.vo2max_percentile(45, age: 60, sex: :male)    # => 95.0
```

| Percentile (same sex and age decade) | Level     |
|--------------------------------------|-----------|
| ≥ 95th                               | Elite     |
| 90th–94th                            | Excellent |
| 75th–89th                            | Very Good |
| 50th–74th                            | Good      |
| 25th–49th                            | Fair      |
| < 25th                               | Beginner  |

- The cuts sit on percentiles the table publishes (5th, 10th, 25th, 50th,
  75th, 90th, 95th), so a label never depends on interpolation. They are
  calcpace's choice: FRIEND publishes percentiles, not labels.
- `vo2max_percentile` interpolates linearly between the published percentiles,
  rounded to one decimal, and is bounded to the table: `5.0` means at or below
  the 5th percentile, `95.0` at or above the 95th.
- Age decades (20–29 … 70–79) are used as published, without blending, so a
  29- and a 30-year-old read different rows. Ages 18–19 use the 20–29 row and
  80+ the 70–79 row; under 18 raises `ArgumentError`, as does a sex other than
  male/female. Age and sex must be given together.
- The registry measured VO2max in a lab; a VO2max estimated from a race time
  carries its own ±3–5 ml/kg/min on top.

*Kaminsky, L. A., Arena, R., & Myers, J. (2015). Reference Standards for Cardiorespiratory Fitness Measured With Cardiopulmonary Exercise Testing: Data From the Fitness Registry and the Importance of Exercise National Database. Mayo Clinic Proceedings, 90(11), 1515–1523, Table 3 (rows "Men/Women from FRIEND"; 7,783 treadmill tests on adults free of known cardiovascular disease). https://doi.org/10.1016/j.mayocp.2015.07.026. The same table also lists the Cooper Clinic norms printed in ACSM's Guidelines for Exercise Testing and Prescription (9th ed., 2014); those are predicted from treadmill time rather than measured, and are not used here.*

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
zones[:marathon].fast_clock    # => "00:04:31" per km (the VDOT-predicted marathon pace)

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
| Marathon | 75% – predicted marathon pace (0.800–0.849) | Marathon race pace |
| Threshold | 83–88% | Lactate threshold, tempo runs |
| Interval | 95–100% | VO2max development |
| Repetition | 105–110% | Speed and running economy |

Pace accuracy vs published VDOT tables: within a few seconds per km
(threshold matches exactly; easy band is a range heuristic). The fast end of the
marathon band is the marathon pace `predict_time_from_vo2max` gives for the same
VO2max (Daniels' M pace is the predicted marathon race pace); that prediction
covers VO2max 10–100, and outside it the race-pace intensity of the nearest bound
is used. That intensity is 0.800–0.849 of VO2max (0.805 at VO2max 30, 0.830 at 70),
so the marathon band stays slower than the threshold band below VO2max ~69.5, as in
Daniels. `TRAINING_INTENSITIES[:marathon][:high]` stays 0.84 as the nominal upper
bound; `PREDICTED_RACE_PACE_ZONES` lists the zones whose fast end is the predicted
race pace.

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

Every time or pace string the gem reads goes through `convert_to_seconds`, so
every method reads the same clocks — exactly the ones the gem writes:

```ruby
calc.convert_to_seconds('75:00')       # => 4500     (MM:SS keeps counting minutes)
calc.convert_to_seconds('400:00:00')   # => 1440000  (any number of hours)
calc.convert_to_seconds('1 03:46:40')  # => 100000   (convert_to_clocktime's day prefix)
calc.convert_to_seconds('-0:40')       # => -40      (a backwards track_splits split)
```

Seconds must be two digits below 60, and so must minutes when hours are given;
after a day prefix the hours are two digits below 24. A leading `-` is the only
sign, and blanks or surrounding whitespace are not trimmed. Anything else —
`'05:99'`, `'1:60:00'`, `'1 3:46:40'`, `' 05:00'`, `'abc'` — raises
`Calcpace::InvalidTimeFormatError`. A negative clock parses, but every method
that needs a positive time or pace rejects it with `Calcpace::NonPositiveInputError`.

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

- `Calcpace::NonPositiveInputError` — numeric input is zero, negative, NaN or infinite
- `Calcpace::InvalidTimeFormatError` — time string that is not a clock the gem writes
  (`[-][D ]H:MM:SS` or `[-]M:SS`, see Other Utilities): seconds must be below 60, and
  so must minutes when hours are given (`'05:99'` and `'1:60:00'` raise)
- `Calcpace::UnsupportedUnitError` — unknown conversion (`convert`) or unknown
  `unit:` / `distance_unit:` keyword
- `Calcpace::InvalidDataError` — the bundled data table failed its load-time
  consistency check (raised on `require`, never for user input)

Argument validation that is not about units or numbers raises a plain `ArgumentError`:
unknown race names, unsupported age-grading distances, and invalid `age` / `sex` values.

---

### Testing

```bash
bundle exec rake
```

Requires Ruby >= 3.3.0. Tested with Ruby 3.3, 3.4, and 4.0.

## Contributing

Clone the repo and submit a pull request. Please include tests.

## License

[MIT License](https://opensource.org/licenses/MIT)
