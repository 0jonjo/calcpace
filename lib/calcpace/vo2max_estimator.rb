# frozen_string_literal: true

# Module for estimating VO2max from a race performance
#
# Uses the Daniels & Gilbert formula (1979), which relates running velocity
# and exercise duration to oxygen consumption as a percentage of VO2max.
#
# Formula:
#   velocity (m/min)  = distance_m / time_min
#   VO2               = -4.60 + 0.182258 * v + 0.000104 * v²
#   %VO2max           = 0.8 + 0.1894393·e^(-0.012778·t) + 0.2989558·e^(-0.1932605·t)
#   VO2max            = VO2 / %VO2max
#
# Accuracy: ±3–5 ml/kg/min vs laboratory testing. Best results with efforts
# between 5 and 60 minutes at race pace (i.e. near-maximal effort).
module Vo2maxEstimator
  # Classification thresholds based on:
  # Daniels, J. (2014). Daniels' Running Formula (3rd ed.). Human Kinetics.
  # General ranges are consistent with ACSM guidelines and widely cited in
  # exercise physiology literature (McArdle, Katch & Katch, 2015).
  VO2MAX_LABELS = [
    { min: 70, label: 'Elite' },
    { min: 60, label: 'Excellent' },
    { min: 50, label: 'Very Good' },
    { min: 40, label: 'Good' },
    { min: 30, label: 'Fair' },
    { min: 0,  label: 'Beginner' }
  ].freeze

  # Represents a contextualized VO2max estimation result
  Vo2maxResult = Struct.new(:value, :confidence, :sub_maximal, :adjusted_distance_km)

  # Estimates VO2max from a race performance using Daniels & Gilbert formula
  #
  # @param distance_km [Numeric] race distance in kilometres (must be > 0)
  # @param time [String, Integer] finish time as "HH:MM:SS" / "MM:SS", or total seconds (must be > 0)
  # @return [Float] estimated VO2max in ml/kg/min, rounded to one decimal place
  # @raise [Calcpace::NonPositiveInputError] if distance or time are not positive
  # @raise [Calcpace::InvalidTimeFormatError] if time string is not in HH:MM:SS or MM:SS format
  #
  # @example 10 km in 40:00 → ~51.9 ml/kg/min
  #   calc = Calcpace.new
  #   calc.estimate_vo2max(10.0, '00:40:00') #=> 51.9
  def estimate_vo2max(distance_km, time)
    distance_m = distance_km.to_f * 1000
    time_min   = parse_time_minutes(time)

    check_positive(distance_m, 'Distance')
    check_positive(time_min,   'Time')

    velocity    = distance_m / time_min
    vo2         = vo2_at_velocity(velocity)
    pct_vo2max  = percent_vo2max(time_min)

    (vo2 / pct_vo2max).round(1)
  end

  # Estimates a detailed and contextualized VO2max
  #
  # @param distance_km [Numeric] race distance in kilometres
  # @param time [String, Integer] finish time
  # @param elevation_gain_m [Numeric] total elevation gain in metres
  # @param hr_avg [Numeric] average heart rate during the effort
  # @param hr_max [Numeric] athlete's maximum heart rate
  # @return [Vo2maxResult] structured result with value and metadata
  def estimate_detailed_vo2max(distance_km, time, elevation_gain_m: 0, hr_avg: nil, hr_max: nil)
    # 1. Elevation adjustment (Naismith-based heuristic: 100m gain = +600m flat)
    adjusted_distance_m = (distance_km.to_f * 1000) + (elevation_gain_m.to_f * 6.0)
    adjusted_distance_km = adjusted_distance_m / 1000.0

    # 2. Base VO2max calculation
    vo2max_value = estimate_vo2max(adjusted_distance_km, time)

    # 3. Confidence based on effort duration
    time_min = parse_time_minutes(time)
    confidence = calculate_time_confidence(time_min)

    # 4. HR validation for sub-maximal effort
    sub_maximal = false
    if hr_avg && hr_max
      check_positive(hr_avg, 'Average heart rate')
      check_positive(hr_max, 'Maximum heart rate')

      avg = hr_avg.to_f
      max = hr_max.to_f

      raise Calcpace::Error, "Average heart rate (#{avg}) cannot exceed maximum heart rate (#{max})" if avg > max

      # If effort is below 85% of HRmax, it's considered sub-maximal
      if (avg / max) < 0.85
        sub_maximal = true
        confidence = :low
      end
    end

    Vo2maxResult.new(
      value: vo2max_value,
      confidence: confidence,
      sub_maximal: sub_maximal,
      adjusted_distance_km: adjusted_distance_km.round(2)
    )
  end

  # Returns a descriptive label for a given VO2max value
  #
  # @param value [Numeric] VO2max in ml/kg/min
  # @return [String] label: "Beginner", "Fair", "Good", "Very Good", "Excellent", or "Elite"
  # @raise [ArgumentError] if value is not positive
  #
  # @example
  #   calc.vo2max_label(51.9) #=> "Very Good"
  def vo2max_label(value)
    check_positive(value.to_f, 'VO2max value')

    VO2MAX_LABELS.find { |entry| value.to_f >= entry[:min] }[:label]
  end

  private

  def calculate_time_confidence(time_min)
    if time_min.between?(5, 60)
      :high
    elsif time_min > 60 && time_min <= 120
      :medium
    else
      :low
    end
  end

  def vo2_at_velocity(velocity)
    -4.60 + (0.182258 * velocity) + (0.000104 * (velocity**2))
  end

  def percent_vo2max(time_min)
    0.8 +
      (0.1894393 * Math.exp(-0.012778 * time_min)) +
      (0.2989558 * Math.exp(-0.1932605 * time_min))
  end

  def parse_time_minutes(time)
    return time.to_f / 60.0 if time.is_a?(Numeric)

    check_time(time.to_s)
    convert_to_seconds(time.to_s) / 60.0
  end
end
