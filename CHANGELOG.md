# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Humidity in the heat penalty.** `calculate_penalty` — and therefore
  `adjust_time`, `normalize_time`, `predict_time_adjusted` and
  `predict_time_cameron_adjusted`, which forward their options — accepts
  `humidity:` (relative humidity, 0–100 %) or `dew_point:` (in
  `temperature_unit`). 30 °C dry and 30 °C at 80% (typical of coastal Brazil)
  used to get the same penalty. The temperature is replaced by an effective
  temperature: the air temperature that, at `REFERENCE_HUMIDITY` (50%), has the
  same simplified WBGT (Australian Bureau of Meteorology:
  `WBGT = 0.567·Ta + 0.393·e + 3.94`, `e` = vapour pressure in hPa) as the real
  temperature and humidity, solved exactly (by bisection). The existing heat
  curve and the `base(temperature) × duration_factor(seconds)` shape are
  untouched; the curve is read at the unrounded effective temperature, so
  `humidity: 50` gives exactly the temperature-only numbers. 50% is the
  humidity at which that WBGT equals the air temperature between 20 °C and
  35 °C (51–56%), i.e. how the temperature-only points already read. `factors`
  gains `:effective_temperature_celsius` (rounded to 2 decimals) when humidity
  or dew point is given. `ArgumentError` for humidity outside 0–100, NaN,
  Complex or non-numeric; a dew point above the temperature, below −100 °C or
  not a finite real number; both keywords together; or either without a
  finite temperature. The marathon outcome studies (El Helou 2012, Vihma 2010)
  found no humidity effect independent of temperature, so the size of this
  adjustment rests on the WBGT index, not on race data.

  | 30 °C at | Effective temperature | 60 min | 4 h |
  | --- | --- | --- | --- |
  | 30% RH | 26.69 °C | 5.46% | 15.34% |
  | 50% RH (= no humidity) | 30.0 °C | 7.9% | 22.2% |
  | 70% RH | 33.07 °C | 10.46% | 29.39% |
  | 90% RH | 35.94 °C (capped at 35 °C) | 12.16% | 34.17% |

### Changed (numbers)
Four models produced unrealistic numbers. The method names, signatures, return
shapes and the structure of `environmental_factors.yml` are unchanged; only the
values they return move, except that Cameron predictions now reject distances
above 100 km (see Breaking).

- **Cameron prediction now uses Dave Cameron's actual model.** The previous
  constants (`a + b·e^(−d/c)` with a = 0.000495, b = 0.000985, c = 1.4485) were
  not Cameron's formula and were far more optimistic than Riegel for the
  marathon, while the real model is more conservative. `predict_time_cameron`
  and friends now use Cameron's velocity-ratio function, with distances in
  metres as in his own metric version (t-and-f mailing list, 20 Jun 2001) and
  the had2know.org calculator:
  `f(d) = 13.49681 − 0.000030363·d + 835.7114 / d^0.7905`,
  `T2 = T1 · (D2/D1) · f(D1)/f(D2)`. Distances are still passed in km or as race
  names. The model is fitted from 800 m to the marathon and f(d) crosses zero
  near 445 km, so distances above `CAMERON_MAX_DISTANCE_KM` (100 km, which keeps
  the standard `'100k'` race usable) now raise `ArgumentError` on either end,
  in every Cameron method. Without that limit the formula returns a negative
  time for a 500 km target, and sources from 400 km up give nonsense or raise
  from the clock conversion.
- **Altitude no longer jumps at 914 m and no longer stops at 2438 m.** The
  threshold moves from 914.4 m to 300 m with a new `300: 0.0` point, so the
  penalty ramps linearly up to the first NCAA point (914.4 m → 1.41%) instead of
  jumping from 0% at 914 m to 1.41% at 915 m. The NCAA points are unchanged.
  Above 2438.4 m, where everything used to be capped at 5.90%, three points are
  extrapolated from a quadratic fit to the NCAA table
  (`p = 0.3647·x² + 1.9482·x`, `x = km − 0.3`): 3000 m → 7.92%,
  3500 m → 9.97%, 4000 m → 12.2% (capped there). The redundant `0: 0.0` point is
  gone; the YAML keys are the same.
- **Negative/positive race splits are ±1% per half instead of ±4%.** A 3:00:00
  marathon with `strategy: :negative` used to go through halfway in 1:33:36 (a
  7-minute negative split); it now splits 1:30:54 + 1:29:06.
- **Heat above 30 °C keeps increasing.** 35 °C and 40 °C used to get the same
  penalty as 30 °C. The base curve now continues to 35 °C (12.16% for 60
  minutes, extrapolating the fitted law below) and is capped there: 35–40 °C
  and hotter all read like 35 °C. The ideal range is unchanged.
- **Heat base curve and duration scaling are fitted to marathon data.** The
  60-minute base was 2.8 / 4.3 / 6.5% at 20 / 25 / 30 °C (roughly linear) and
  the duration factor 1.0× (60 min) → 3.0× (3 h) → 4.5× (4 h), with the 3 h
  point justified by Ely 2007 percentages for a 3 h runner (~9% at 20 °C,
  ~12% at 25 °C) that the paper's abstract does not contain. Both are now
  fitted to El Helou et al. (2012, PLoS One 7(5):e37407, Table S3; 1.79 M
  finishers of six majors, 2001–2010):
  1. speed loss at 15, 20 and 25 °C, straight line between the table's points
     (each group's optimum −10 … +20 °C);
  2. time penalty against 15 °C, where the gem's curve is zero:
     `P = ((1 − loss15) / (1 − lossT) − 1) × 100`;
  3. **base shape**: P25/P20 is 2.70–2.97 in every group, so `P ∝ (T − 15)^p`
     with `p = log2(P25/P20)`; the sex-weighted mean (each sex half the
     weight) is 1.497 → **1.5**. Base = `4.3 · ((T − 15)/10)^1.5`, keeping the
     original 25 °C / 60-minute anchor of 4.3% (the only value available for a
     60-minute effort), stored every 2.5 °C from 15 to 40 °C (linear
     interpolation stays within 0.08 points of the curve): 0, 0.54, 1.52,
     2.79, 4.3, 6.01, 7.9, 9.95, 12.16, then 12.16 and 12.16 at 37.5 and
     40 °C. Above 25 °C this is an extrapolation (El Helou's hottest race was
     25.2 °C), so the curve is deliberately capped at 35 °C: the uncapped law
     (14.51 at 37.5 °C, 17.0 at 40 °C) gave 47.77% for 4 h at 40 °C;
  4. ratio = P ÷ base(T); finish time = 42195 m ÷ the group's speed at its
     optimum;
  5. **duration factor**: weighted least squares over the 15 ratios (men P1 at
     25 °C is beyond the table), each sex half the weight, 0.5× (≤30 min) and
     1.0× (60 min) kept, 180 and 240 min free, flat after 240: 1.761 / 2.814 →
     **1.76× at 3 h, 2.81× at 4 h** (1.38× at 2 h on the straight line). A free
     150-min point cut the weighted residual by 1%; a free 210-min point made
     the curve non-monotonic (2.97 > 2.73 at 240). Neither was kept.

  | Group | Finish | loss@15 | loss@20 | loss@25 | P20 | P25 | P25/P20 | ratio @20 | ratio @25 |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | men P1 | 2:41 | 1.88 | 3.93 | n/a | 2.14 | n/a | n/a | 1.41 | n/a |
  | women P1 | 3:06 | 0.79 | 3.13 | 7.27 | 2.42 | 6.99 | 2.89 | 1.59 | 1.63 |
  | men Q1 | 3:31 | 2.86 | 7.00 | 13.58 | 4.46 | 12.41 | 2.78 | 2.93 | 2.89 |
  | men median | 3:57 | 3.18 | 7.93 | 15.63 | 5.17 | 14.76 | 2.86 | 3.40 | 3.43 |
  | women Q1 | 4:00 | 1.86 | 4.73 | 9.26 | 3.02 | 8.16 | 2.70 | 1.99 | 1.90 |
  | women median | 4:25 | 2.09 | 5.30 | 10.40 | 3.39 | 9.27 | 2.73 | 2.23 | 2.16 |
  | men Q3 | 4:28 | 2.92 | 7.91 | 16.38 | 5.42 | 16.10 | 2.97 | 3.57 | 3.74 |
  | women Q3 | 4:54 | 2.03 | 5.37 | 10.80 | 3.54 | 9.83 | 2.78 | 2.33 | 2.29 |

  Losses and P in %. With the new base, each group's ratio is almost the same
  at 20 and 25 °C, so `base(T) × duration_factor(seconds)` fits; the weighted
  residual in penalty points drops from 18.3 (linear base, 1.24×/2.18×) to
  8.8. What remains is mostly sex: with no sex input, men's slower groups are
  under-read at 25 °C (median 11.9% vs 14.76%) and women's over-read (median
  12.08% vs 9.27%) — see Known limitations below. Ely et al. (2007) remains a qualitative source (top men
  1.7 / 2.5 / 3.3 / 4.5% off the course record across WBGT 5–10 … 20–25 °C,
  i.e. +2.8 points); the model gives a 2:10 effort 4.03% at 22.5 °C against
  0% at 7.5 °C, a little above that for elite runners. The duration points
  live in `EnvironmentalAdjuster::HEAT_DURATION_FACTORS`;
  `duration_factor(time_seconds)` and the `environmental_factors.yml` keys are
  unchanged.

  | Heat penalty (%), 1.18.1 → now | 20 min | 60 min | 120 min | 180 min | 240 min | 300 min |
  | --- | --- | --- | --- | --- | --- | --- |
  | 20 °C | 1.4 → 0.76 | 2.8 → 1.52 | 5.6 → 2.1 | 8.4 → 2.68 | 12.6 → 4.27 | 12.6 → 4.27 |
  | 25 °C | 2.15 → 2.15 | 4.3 → 4.3 | 8.6 → 5.93 | 12.9 → 7.57 | 19.35 → 12.08 | 19.35 → 12.08 |
  | 30 °C | 3.25 → 3.95 | 6.5 → 7.9 | 13.0 → 10.9 | 19.5 → 13.9 | 29.25 → 22.2 | 29.25 → 22.2 |
  | 35 °C | 3.25 → 6.08 | 6.5 → 12.16 | 13.0 → 16.78 | 19.5 → 21.4 | 29.25 → 34.17 | 29.25 → 34.17 |
  | 40 °C | 3.25 → 6.08 | 6.5 → 12.16 | 13.0 → 16.78 | 19.5 → 21.4 | 29.25 → 34.17 | 29.25 → 34.17 |

- **The marathon pace band ends at the runner's predicted marathon pace.**
  Daniels' M pace is the predicted marathon race pace, but
  `training_paces(50)[:marathon]` ran from 4:50 to 4:25/km (75–84% VO2max)
  while the VDOT marathon prediction for VO2max 50 is 3:10:39, 4:31/km. The
  fast end now comes from `predict_time_from_vo2max(vo2max, 'marathon')`
  (0.800–0.849 of VO2max across VO2max 10–100; 0.805 at 30, 0.830 at 70); the
  slow end stays at 75%. The prediction covers VO2max 10–100, and beyond it
  the race-pace fraction of the nearest bound is used, so `training_paces`
  still accepts any positive VO2max. `TRAINING_INTENSITIES` stays all-numeric
  (`marathon: { low: 0.75, high: 0.84 }`, the nominal upper bound); the new
  `PREDICTED_RACE_PACE_ZONES` (`%i[marathon]`) names the zones whose fast end
  is the predicted race pace. As a result the marathon and threshold bands no
  longer overlap below VO2max ~69.5 (the threshold band starts at 0.83): M
  pace is slower than T pace, as in Daniels. At VO2max 70 they touch (3:24).

  | VO2max | M band before | M band after | Predicted marathon pace |
  | --- | --- | --- | --- |
  | 30 | 7:15–6:38/km | 7:15–6:52/km | 6:52/km |
  | 40 | 5:47–5:17/km | 5:47–5:27/km | 5:27/km |
  | 50 | 4:50–4:25/km | 4:50–4:31/km | 4:31/km |
  | 60 | 4:11–3:49/km | 4:11–3:52/km | 3:52/km |
  | 70 | 3:41–3:22/km | 3:41–3:24/km | 3:24/km |

| Case | Before (1.18.1) | After |
| --- | --- | --- |
| Cameron 10K 42:00 → marathon | 02:57:34 | 03:16:46 (Riegel 03:13:12) |
| Cameron 5K 20:00 → marathon | 02:59:25 | 03:15:11 (Riegel 03:11:49) |
| Cameron 5K 20:00 → 10K | 00:42:26 | 00:41:39 |
| Cameron 7.79 km 26:59 → half marathon | 01:13:44 | 01:17:26 |
| Altitude 500 m | 0.0% | 0.46% |
| Altitude 760 m (São Paulo) | 0.0% | 1.06% |
| Altitude 914 m / 915 m | 0.0% / 1.41% | 1.41% / 1.41% |
| Altitude 2800 m | 5.9% | 7.2% |
| Altitude 3600 m | 5.9% | 10.42% |
| Heat 20 °C, 60 min | 2.8% | 1.52% |
| Heat 30 °C, 60 min | 6.5% | 7.9% |
| Heat 35 °C, 60 min | 6.5% | 12.16% |
| Heat 40 °C, 60 min | 6.5% | 12.16% |
| Heat 25 °C, 2 h | 8.6% | 5.93% |
| Heat 25 °C, 3 h | 12.9% | 7.57% |
| Heat 25 °C, 4 h | 19.35% | 12.08% |
| Heat 30 °C, 4 h | 29.25% | 22.2% |
| Heat 35 °C, 4 h | 29.25% | 34.17% |
| Heat 40 °C, 4 h | 29.25% | 34.17% |
| Marathon band, VO2max 50 | 4:50–4:25/km | 4:50–4:31/km |
| Splits marathon 3:00:00 `:negative` (halves) | 1:33:36 + 1:26:24 | 1:30:54 + 1:29:06 |
| Splits marathon 3:00:00 `:positive` (halves) | 1:26:24 + 1:33:36 | 1:29:06 + 1:30:54 |

### Known limitations
- **The heat model has no sex term.** One curve serves everyone, and El Helou
  et al. (2012) Table S3 shows men slowing more than women in the heat: at
  25 °C the model reads men's slower groups low (men's median 11.9% vs 14.76%
  observed, Q3 12.08% vs 16.10%) and women's high (women's median 12.08% vs
  9.27%, Q1 12.08% vs 8.16%).

### Breaking
- Removed `CameronPredictor::CAMERON_A`, `CAMERON_B` and `CAMERON_C`. They described
  the wrong formula, and keeping them would suggest they still drive the
  prediction. The new model's constants are `CAMERON_CONSTANT`,
  `CAMERON_LINEAR_COEFFICIENT`, `CAMERON_POWER_COEFFICIENT` and
  `CAMERON_POWER_EXPONENT`.
- Cameron predictions (`predict_time_cameron`, `_clock`, `predict_pace_cameron`,
  `_clock`, `predict_time_cameron_adjusted`) raise `ArgumentError` when either
  distance exceeds `CAMERON_MAX_DISTANCE_KM` (100 km). 1.18.1 accepted any
  distance, but Cameron's model is only fitted up to the marathon and breaks
  down past ~445 km.
### Breaking
- The public `AgeGrading::WMA_DATA` constant no longer has the track keys
  (`"1500"`, `"3000"`): each sex now holds only the road distances the gem
  grades — `"5000"`, `"10000"`, `"21097"` and `"42195"`. Code that read
  `WMA_DATA["M"]["1500"]` (or `"3000"`) directly gets a `KeyError` / `nil`.
  Its factor tables also start at age 18 and end at 100 (they were 30–110).

### Changed
- **Age grading now uses the 2025 road tables.** Age factors and open
  standards come from Alan Jones' 2025 road age-grading tables, approved on
  2025-01-10 by the USATF Masters Long Distance Running Council
  ([source spreadsheets](https://github.com/AlanLyttonJones/Age-Grade-Tables/tree/4aac6737cb9f216c90a0a610355667cd3d921c61/2025%20Files):
  `MaleRoadStd2025.xlsx`, `FemaleRoadStd2025.xlsx`). The previous data,
  despite the `wma_2023_road.yml` name, came from the WMA 2023 **track and
  field** tables: track open standards (5000 m 12:35 / 14:06, 10 000 m
  26:11 / 29:01), an outdated women's marathon standard (2:14:04), and no
  factors under age 30. Road age grades were off by about 1–3%.
- New open standards — men: 5K 12:49, 10K 26:24, half 57:31, marathon
  2:00:35; women: 5K 13:54, 10K 28:46, half 1:02:52, marathon 2:09:56.
- One factor per year of age from 18 to 100. Runners under 30 now get the
  table's real factors instead of 1.0 (e.g. a male 18-year-old at 5K: 0.9995;
  a female 30-year-old at 5K: 0.9959). The old table ran to 110; the 2025
  road tables end at 100, so ages 101 and over now use the age-100 factor.
- `table_version` is now `"MLDR_2025_ROAD_ONE_YEAR_FACTORS_V1"` (was
  `"WMA_2023_ONE_YEAR_FACTORS_V1"`). The data files were renamed to
  `lib/calcpace/data/mldr_2025_road.yml` and
  `lib/calcpace/data/mldr_2025_road_open_standards.yml`; `DATA_PATH`,
  `OPEN_STANDARDS_DATA_PATH`, `WMA_DATA`, `OPEN_STANDARDS_DATA` and
  `TABLE_VERSION` keep their names and shapes (see Breaking for the keys
  `WMA_DATA` lost). Category labels are unchanged.

  | Case | Before (WMA 2023 track) | After (2025 road) | Official 2025 |
  | --- | --- | --- | --- |
  | Male 40, marathon 3:30:00 | 58.8% (factor 0.9804) | 58.7% (0.9783) | 58.7% |
  | Female 50, marathon 4:00:00 | 62.7% (0.8915) | 60.2% (0.8998) | 60.2% |
  | Female 30, 5K 25:00 | 56.4% (1.0) | 55.8% (0.9959) | 55.8% |
  | Male 60, half 1:50:00 | 63.3% (0.8264) | 64.7% (0.8082) | 64.7% |
  | Male 55, 10K 45:00 | 69.0% (0.8438) | 68.9% (0.8511) | 68.9% |

  "Official" is age standard / time from the spreadsheets' `AgeStdSec` sheet,
  at one decimal.
- `predict_marathon_from_training(weekly_distance:, training_pace:, unit: :km)`
  predicts a marathon from the mean weekly distance and mean training pace of
  the 8 weeks before the race, with Tanda (2011), *Journal of Human Sport and
  Exercise* 6(3):511–520: `Pm = 17.1 + 140.0 · exp(−0.0053 · K) + 0.55 · P`.
  Returns `:time`, `:time_clock`, `:pace`, `:pace_clock` (in `unit`, `:km` or
  `:mi`), `:within_validated_range` and `:out_of_range`, which lists any of
  `:weekly_distance` (sample: 40.4–110.7 km/week), `:training_pace`
  (253.3–330.6 s/km) and `:marathon_time` (167–216 min) that fall outside the
  paper's sample. Out of range is a flag, not an error.

  ```ruby
  calc.predict_marathon_from_training(weekly_distance: 60, training_pace: '05:00')[:time_clock] # => "03:19:41"
  ```
- `riegel_exponent(race1, time1, race2, time2)` fits a personal Riegel
  exponent, `ln(t2/t1) / ln(d2/d1)`, to two performances.
- `predict_time_personal(race1, time1, race2, time2, to_race)` predicts with
  that exponent. A target between the two races is interpolated along the
  curve through both, with the raw exponent (never clamped, independent of
  argument order); a target outside the pair is extrapolated from the closer
  performance in log-distance, with the exponent clamped to 1.01–1.20.
  Returns `:time`, `:time_clock`, `:exponent`, `:raw_exponent` and
  `:clamped`; an exponent that needed clamping usually means one of the races
  was not all-out.

  ```ruby
  calc.predict_time_personal('10k', '00:45:00', 'half_marathon', '01:42:00', 'marathon')[:time_clock] # => "03:38:03"
  ```

### Fixed
- `check_positive` let `Float::INFINITY` through, so every method guarded by it
  accepted an infinite distance or time: an infinite weekly distance became a
  finite (and fast) marathon prediction, an infinite pace a `FloatDomainError`
  far from the input. Infinity now raises `Calcpace::NonPositiveInputError`
  ("must be a finite positive number"), like zero, negatives and NaN already
  did.

## [1.18.1] - 2026-09-06

### Fixed
- `age_grade_label(Float::NAN)` raised an opaque `NoMethodError` (`undefined
  method '[]' for nil`) instead of a clear error; it now raises
  `ArgumentError`. `Float::INFINITY` is unchanged and still maps to the top
  band, "Approximate World Record Level".

### Changed
- `AGE_GRADE_LABELS` is now sorted by `min` descending at load time and
  validated to be strictly descending with a `min` of exactly `0.0` on the
  last entry, raising `Calcpace::InvalidDataError` at require time otherwise.
  `age_grade_label` walks the list in order and returns the first match, so
  an out-of-order entry in the data file would have silently misclassified
  percentages, and a missing zero floor raised an opaque `NoMethodError`
  instead of failing loudly.
- Corrected the provenance note for the age-grade categories in the README
  and in `wma_2023_open_standards.yml`. The WMA / Alan Jones (Howard Grubb)
  tables are numeric age factors and open standards only — they define no
  categories at all. The bands from Local Class (60%) upward follow the
  USATF Masters / National Masters News convention; the three bands below
  60% remain calcpace's own extension for recreational runners. No band
  boundaries or labels changed, only the attribution text.
- Documented in the README that the bands apply to the percentage as
  reported by `age_grade` (rounded to one decimal), so calling
  `age_grade_label` directly on an unrounded value can land one band lower
  at an edge.

## [1.18.0] - 2026-09-06

### Breaking
- **`age_grade[:category]` and `age_grade_label` return different strings for
  anything below 60%.** The old single `"Developing"` band below 60% is now
  three bands: `"Intermediate"` (50–59.9%), `"Recreational"` (40–49.9%) and
  `"Active Beginner"` (below 40%). Most recreational runners grade under 60%,
  so the old catch-all told nearly every one of them the same thing. A caller
  matching on the string `"Developing"` must update — that string is no
  longer returned by either method.

  ```ruby
  calc.age_grade_label(55.0) # => "Intermediate"      (was "Developing")
  calc.age_grade_label(45.0) # => "Recreational"      (was "Developing")
  calc.age_grade_label(30.0) # => "Active Beginner"   (was "Developing")
  ```

  The bands at 60% and above are untouched, and the numeric fields —
  `age_grade_percent`, `age_graded_time_seconds` and the rest — are
  unaffected; only the two label-returning methods changed.

## [1.17.0] - 2026-09-05

### Added
- `time_in_zones(heartrate:, time:, zones:)` — splits a recorded heart-rate
  series into the seconds spent in each of the five zones returned by `hr_zones`
  or `hr_zones_from_max`, plus each zone's share of the counted time. Inputs are
  two plain arrays, so a Strava `heartrate`/`time` stream pair fits without
  translation and so does the same pair read out of a FIT file.

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

  A sample lasts until the next one, and the last sample inherits the previous
  delta so a series does not lose its final seconds. **A pause is a gap in
  `time`, and the whole gap is booked to the sample before it** — there is no
  `max_gap` to guess a cut-off with, so a caller holding Strava's `moving`
  stream should nil the heart rate of every paused sample first.

  A sample with a nil or non-positive heart rate contributes nothing — its
  duration is dropped, never reassigned to a neighbour. Shares are rounded
  together, largest remainder first, so the five of them are whole thousandths
  adding up to 1000 — a bar chart fills its track.

- `hr_zone_for(bpm, zones)` — the zone lookup `time_in_zones` uses, exposed on
  its own. Returns the `HrZone`, or nil when the reading is nil or not positive.

  ```ruby
  calc.hr_zone_for(150, calc.hr_zones_from_max(hr_max: 190)).zone  # => 3
  calc.hr_zone_for(114, calc.hr_zones_from_max(hr_max: 190)).zone  # => 2
  calc.hr_zone_for(205, calc.hr_zones_from_max(hr_max: 190)).zone  # => 5
  ```

  **Note for calcpace.app:** the site's own lookup walks the zones with
  `between?`, which differs from this one in two places. Zones are contiguous,
  so their bounds are shared: `between?` gives 114 bpm to Z1, while
  `hr_zone_for` gives it to Z2, the way a watch reads it. And a reading above
  `hr_max` returns nil from `between?` but Z5 here — a reading above the maximum
  means the maximum is wrong, not that the beat did not happen. Consumers should
  migrate to `hr_zone_for` so that a zone split and a live zone badge cannot
  disagree about the same beat.

- `interval_structure(laps, unit: :km)` — new `LapAnalyzer` module. Detects a
  structured interval session in a watch's laps by **contrast**, never by a
  label: a lap is work when it covers at least 0.1 km and is at least 15% faster
  than every lap touching it. What comes before the first work lap is warm-up,
  what follows the last is cool-down, and what sits between two work laps is
  rest.

  ```ruby
  laps = [{ distance: 2.0, elapsed: 720 }] +
         ([{ distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 156 }] * 6) +
         [{ distance: 1.5, elapsed: 495 }]

  calc.interval_structure(laps)
  # => #<struct reps=6, work_distance=1.0, ... rest_duration=156>
  ```

  A warm-up or a cool-down has only one neighbour, so contrast alone would be a
  free pass — a 5:30/km cool-down beats the 6:30/km jog it touches and walks in
  as an extra rep. An edge lap is therefore admitted only if it also agrees with
  the reps found in the interior: within ±25% of their median distance and no
  more than 10% slower than their pace.

  It returns `nil` when the laps describe no structure — fewer than two work
  laps, work laps more than ±25% away from their median distance (a fartlek or a
  hilly run), or no work lap that ever beat a *finite* pace. That last rule
  matters because a standing lap has an infinite pace and everything is 15%
  faster than infinity: without it, an easy run with two red-light lap presses
  would come back as three reps. Most runs are not intervals, and inventing reps
  out of ordinary pace variation would make every easy run look like a workout.

  A distance of `0` is a legal standing recovery, and makes `rest_pace` nil
  rather than infinite. A lap over 100 km is rejected: it is a caller who passed
  metres. `unit: :mi` converts both paces; distances stay in kilometres.

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

[Unreleased]: https://github.com/0jonjo/calcpace/compare/v1.18.1...HEAD
[1.18.1]: https://github.com/0jonjo/calcpace/compare/v1.18.0...v1.18.1
[1.18.0]: https://github.com/0jonjo/calcpace/compare/v1.17.0...v1.18.0
[1.17.0]: https://github.com/0jonjo/calcpace/compare/v1.16.0...v1.17.0
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
