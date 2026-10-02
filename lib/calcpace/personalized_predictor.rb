# frozen_string_literal: true

# Module for race predictions built from the runner's own data rather than from
# a population-wide constant
#
# Two models live here:
#
# - Tanda (2011): marathon time from the volume and pace of the last weeks of
#   training — no race result needed.
# - A personal Riegel exponent fitted to two of the runner's own performances,
#   used instead of the fixed 1.06 of RacePredictor#predict_time.
module PersonalizedPredictor
  # Tanda (2011) regression coefficients for marathon pace in seconds per km:
  #
  #   Pm = 17.1 + 140.0 · exp(−0.0053 · K) + 0.55 · P
  #
  # K = mean weekly distance (km/week), P = mean training pace (s/km), both
  # averaged over the 8 weeks ending one week before the race.
  #
  # @see https://doi.org/10.4100/jhse.2011.63.05 G. Tanda, "Prediction of
  #   marathon performance time on the basis of training indices", Journal of
  #   Human Sport and Exercise 6(3):511–520, 2011
  TANDA_INTERCEPT = 17.1
  TANDA_VOLUME_AMPLITUDE = 140.0
  TANDA_VOLUME_DECAY = 0.0053
  TANDA_PACE_SLOPE = 0.55

  # Ranges spanned by the paper's sample (Table 2: 22 runners, 21 of them men,
  # 46 marathons). The equation was fitted inside them; outside, it is an
  # extrapolation. The author names the finish-time range as the validity range.
  TANDA_WEEKLY_DISTANCE_RANGE_KM = (40.4..110.7)
  TANDA_TRAINING_PACE_RANGE_SECONDS_PER_KM = (253.3..330.6)
  TANDA_MARATHON_TIME_RANGE_SECONDS = ((167 * 60.0)..(216 * 60.0))

  MARATHON_KM = 42.195

  # Personal Riegel exponents outside this range almost never describe fitness:
  # below 1.01 the longer race was run at practically the shorter one's pace,
  # above 1.20 the runner slows down more than even an untrained endurance
  # profile would — in both cases one of the two races was most likely not an
  # all-out effort (or not on a comparable course or day).
  PERSONAL_EXPONENT_RANGE = (1.01..1.20)

  # Predicts marathon time from training volume and pace — Tanda (2011)
  #
  # Uses Pm = 17.1 + 140.0 · exp(−0.0053 · K) + 0.55 · P, where Pm is marathon
  # pace (s/km), K the mean weekly distance (km/week) and P the mean training
  # pace (s/km) over the 8 weeks ending one week before the race. Training pace
  # is the plain average of every run, warm-ups and recoveries included (total
  # time ÷ total distance), not the pace of the quality sessions. The paper
  # reports a standard error of about 4 minutes on the finish time.
  #
  # Inputs or a predicted time outside the paper's sample do not raise — the
  # prediction is still returned, flagged in :out_of_range.
  #
  # @param weekly_distance [Numeric] mean weekly training distance, in unit per week
  # @param training_pace [Numeric, String] mean training pace per unit, in
  #   seconds or as a clock string ('05:30')
  # @param unit [Symbol, String] :km (default) or :mi — applies to both inputs
  #   and to the returned pace
  # @return [Hash] :time (seconds), :time_clock (HH:MM:SS), :pace (seconds per
  #   unit), :pace_clock, :within_validated_range (Boolean) and :out_of_range
  #   (Array of :weekly_distance, :training_pace and/or :marathon_time)
  # @raise [Calcpace::NonPositiveInputError] if an input is not positive
  # @raise [Calcpace::UnsupportedUnitError] if unit is not :km or :mi
  #
  # @example
  #   calc.predict_marathon_from_training(weekly_distance: 60, training_pace: '05:00')[:time_clock] # => "03:19:41"
  #   calc.predict_marathon_from_training(weekly_distance: 60, training_pace: '05:00')[:pace] # => 283.96
  #   calc.predict_marathon_from_training(weekly_distance: 40, training_pace: '05:30')[:out_of_range]
  #   # => [:weekly_distance, :marathon_time]
  def predict_marathon_from_training(weekly_distance:, training_pace:, unit: :km)
    check_positive(weekly_distance, 'Weekly distance')
    pace_seconds = training_pace.is_a?(String) ? convert_to_seconds(training_pace) : training_pace
    check_positive(pace_seconds, 'Training pace')

    km_per_unit = normalize_distance_km(1, unit)
    weekly_km = weekly_distance * km_per_unit
    pace_km = pace_seconds / km_per_unit

    marathon_pace_km = tanda_marathon_pace(weekly_km, pace_km)
    tanda_result(marathon_pace_km, km_per_unit, tanda_out_of_range(weekly_km, pace_km, marathon_pace_km))
  end

  # Fits a personal Riegel exponent to two performances
  #
  # k = ln(t2 / t1) / ln(d2 / d1). The fixed 1.06 of RacePredictor is a
  # population average; a runner's own k says how much they slow down as the
  # distance grows. A value far from 1.06 — below about 1.01 or above about
  # 1.20 — usually means one of the two races was not an all-out effort, or
  # was run on a course or day that is not comparable.
  #
  # @param race1 [Numeric, String, Symbol] distance in km or race name
  # @param time1 [String, Numeric] time at race1 (HH:MM:SS or seconds)
  # @param race2 [Numeric, String, Symbol] distance in km or race name
  # @param time2 [String, Numeric] time at race2 (HH:MM:SS or seconds)
  # @return [Float] the exponent (order of the two performances does not matter)
  # @raise [ArgumentError] if both races are the same distance or a race name is unknown
  # @raise [Calcpace::NonPositiveInputError] if a distance or time is not positive
  #
  # @example
  #   calc.riegel_exponent('10k', '00:45:00', 'half_marathon', '01:42:00') # => 1.0961
  def riegel_exponent(race1, time1, race2, time2)
    distance1, seconds1 = performance(race1, time1)
    distance2, seconds2 = performance(race2, time2)
    ensure_different_distances!(distance1, distance2)

    Math.log(seconds2 / seconds1) / Math.log(distance2 / distance1)
  end

  # Predicts a race time with a personal Riegel exponent
  #
  # Fits k to the two performances (see #riegel_exponent), clamps it to
  # PERSONAL_EXPONENT_RANGE, and applies Riegel from whichever performance is
  # closer to the target in log-distance — the shorter extrapolation. On an
  # exact tie (target at the geometric mean of the two) the first one is used.
  #
  # @param race1 [Numeric, String, Symbol] distance in km or race name
  # @param time1 [String, Numeric] time at race1 (HH:MM:SS or seconds)
  # @param race2 [Numeric, String, Symbol] distance in km or race name
  # @param time2 [String, Numeric] time at race2 (HH:MM:SS or seconds)
  # @param to_race [Numeric, String, Symbol] target distance in km or race name
  # @return [Hash] :time (seconds), :time_clock (HH:MM:SS), :exponent (the one
  #   used, after clamping), :raw_exponent (as fitted), :clamped (Boolean)
  # @raise [ArgumentError] if the two races are the same distance, the target
  #   is one of them, or a race name is unknown
  # @raise [Calcpace::NonPositiveInputError] if a distance or time is not positive
  #
  # @example
  #   calc.predict_time_personal('10k', '00:45:00', 'half_marathon', '01:42:00', 'marathon')[:time_clock]
  #   # => "03:38:03"
  #   calc.predict_time_personal('10k', '00:45:00', 'half_marathon', '01:42:00', 'marathon')[:clamped] # => false
  def predict_time_personal(race1, time1, race2, time2, to_race)
    raw = riegel_exponent(race1, time1, race2, time2)
    exponent = raw.clamp(PERSONAL_EXPONENT_RANGE.min, PERSONAL_EXPONENT_RANGE.max)
    target = race_distance(to_race)
    anchor_distance, anchor_seconds = closest_performance([performance(race1, time1), performance(race2, time2)],
                                                          target)
    ensure_different_distances!(anchor_distance, target)

    time = (anchor_seconds * ((target / anchor_distance)**exponent)).round(2)
    { time: time, time_clock: convert_to_clocktime(time), exponent: exponent.round(4),
      raw_exponent: raw.round(4), clamped: exponent != raw }
  end

  private

  def tanda_marathon_pace(weekly_km, pace_km)
    TANDA_INTERCEPT + (TANDA_VOLUME_AMPLITUDE * Math.exp(-TANDA_VOLUME_DECAY * weekly_km)) +
      (TANDA_PACE_SLOPE * pace_km)
  end

  def tanda_out_of_range(weekly_km, pace_km, marathon_pace_km)
    checks = {
      weekly_distance: TANDA_WEEKLY_DISTANCE_RANGE_KM.cover?(weekly_km),
      training_pace: TANDA_TRAINING_PACE_RANGE_SECONDS_PER_KM.cover?(pace_km),
      marathon_time: TANDA_MARATHON_TIME_RANGE_SECONDS.cover?(marathon_pace_km * MARATHON_KM)
    }
    checks.reject { |_name, inside| inside }.keys
  end

  def tanda_result(marathon_pace_km, km_per_unit, out_of_range)
    time = (marathon_pace_km * MARATHON_KM).round(2)
    pace = (marathon_pace_km * km_per_unit).round(2)

    {
      time: time,
      time_clock: convert_to_clocktime(time),
      pace: pace,
      pace_clock: convert_to_clocktime(pace),
      within_validated_range: out_of_range.empty?,
      out_of_range: out_of_range
    }
  end

  # A performance as [distance in km, time in seconds], validated
  def performance(race, time)
    seconds = time.is_a?(String) ? convert_to_seconds(time) : time
    check_positive(seconds, 'Time')
    [race_distance(race), seconds.to_f]
  end

  def closest_performance(performances, target)
    performances.min_by { |distance, _seconds| Math.log(target / distance).abs }
  end
end
