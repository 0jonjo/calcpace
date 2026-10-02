# frozen_string_literal: true

require 'yaml'
require_relative 'humidity'

# Module for adjusting race performance based on environmental conditions
#
# Scientific basis:
# - Heat: Matthew Ely et al. (2007) "Impact of Weather on Marathon-Running Performance"
# - Altitude: NCAA Altitude Adjustment Factors (TFRRS)
# - Humidity: Australian Bureau of Meteorology simplified WBGT
#   (WBGT = 0.567·Ta + 0.393·e + 3.94, e = vapour pressure in hPa)
module EnvironmentalAdjuster
  DATA_PATH = File.expand_path('data/environmental_factors.yml', __dir__).freeze
  FACTORS = YAML.safe_load_file(DATA_PATH, permitted_classes: [], aliases: false).freeze

  # Heat duration scaling: [minutes, factor] points, joined by straight lines
  # and flat outside the first and last point. The base heat penalty in
  # environmental_factors.yml is for a 60-minute effort (factor 1.0).
  # - up to 3 h (3.0x): Ely et al. (2007) — a ~3 h marathoner loses ~9% at
  #   20 °C WBGT and ~12% at 25 °C; 2.8 × 3.0 = 8.4%, 4.3 × 3.0 = 12.9%.
  # - 4 h (3.5x, flat after): El Helou et al. (2012, 1.8 M finishers, Table S3).
  #   Men's median (~3:58) loses 8.45% at 20 °C and 16.9% at 25 °C against the
  #   optimum, i.e. 3.0x and 3.9x the 60-minute base; men's Q3 (~4:28) is no
  #   worse (3.0x / 4.1x). The previous 4.5x at 4 h was above every group.
  HEAT_DURATION_FACTORS = [[30.0, 0.5], [60.0, 1.0], [180.0, 3.0], [240.0, 3.5]].freeze

  # Relative humidity (%) the temperature-only heat curve stands for
  # (see EnvironmentalAdjuster::Humidity)
  REFERENCE_HUMIDITY = Humidity::REFERENCE_HUMIDITY

  # Calculates the performance penalty percentage for given environmental conditions
  #
  # @param temperature [Numeric, nil] ambient temperature
  # @param temperature_unit [Symbol, String] :c (Celsius) or :f (Fahrenheit)
  # @param altitude [Numeric, nil] altitude in meters
  # @param time_seconds [Numeric, nil] duration of the effort in seconds
  # @param humidity [Numeric, nil] relative humidity in % (0–100). Optional;
  #   without it (and without dew_point) the heat curve assumes
  #   REFERENCE_HUMIDITY. With it, the temperature is replaced by the effective
  #   temperature that has the same simplified WBGT at REFERENCE_HUMIDITY.
  # @param dew_point [Numeric, nil] dew point, in temperature_unit. Alternative
  #   to humidity (pass one or the other), must not exceed the temperature
  # @return [Hash] hash with :total_penalty_percent and breakdown in :factors;
  #   when humidity or dew_point is given, :factors also carries
  #   :effective_temperature_celsius
  # @raise [ArgumentError] if humidity is outside 0–100, dew_point is above the
  #   temperature, both are given, or either is given without a temperature
  #
  # @example
  #   calc.calculate_penalty(temperature: 30, humidity: 90)[:total_penalty_percent] #=> 9.11
  #   calc.calculate_penalty(temperature: 30, humidity: 90)[:factors][:effective_temperature_celsius] #=> 35.94
  #   calc.calculate_penalty(temperature: 86, dew_point: 77, temperature_unit: :f)[:total_penalty_percent] #=> 8.16
  def calculate_penalty(temperature: nil, temperature_unit: :c, altitude: nil, time_seconds: nil,
                        humidity: nil, dew_point: nil)
    effective = effective_temperature(temperature, temperature_unit, humidity, dew_point)
    heat_penalty = calculate_heat_penalty(effective, time_seconds)
    altitude_penalty = calculate_altitude_penalty(altitude)

    factors = { heat: heat_penalty, altitude: altitude_penalty }
    factors[:effective_temperature_celsius] = effective.round(2) unless humidity.nil? && dew_point.nil?

    { total_penalty_percent: (heat_penalty + altitude_penalty).round(2), factors: factors }
  end

  # Adjusts a given time based on environmental conditions
  #
  # @param time_seconds [Numeric] original time in seconds
  # @param options [Hash] environmental options
  # @return [Hash] hash with adjusted time and penalty details
  def adjust_time(time_seconds, **)
    penalty = calculate_penalty(time_seconds: time_seconds, **)
    percent = penalty[:total_penalty_percent]
    adjusted_seconds = (time_seconds * (1 + (percent / 100.0))).round(2)

    {
      original_time: time_seconds,
      adjusted_time: adjusted_seconds,
      adjusted_time_clock: convert_to_clocktime(adjusted_seconds),
      penalty_percent: percent,
      factors: penalty[:factors]
    }
  end

  # Normalizes a time achieved in non-ideal conditions to its ideal equivalent
  #
  # @param time_seconds [Numeric] performance time in seconds
  # @param options [Hash] environmental options
  # @return [Hash] hash with normalized time and penalty details
  def normalize_time(time_seconds, **)
    penalty = calculate_penalty(time_seconds: time_seconds, **)
    percent = penalty[:total_penalty_percent]
    normalized_seconds = (time_seconds / (1 + (percent / 100.0))).round(2)

    {
      original_time: time_seconds,
      normalized_time: normalized_seconds,
      normalized_time_clock: convert_to_clocktime(normalized_seconds),
      penalty_percent: percent,
      factors: penalty[:factors]
    }
  end

  private

  # Air temperature in °C, moved to the temperature that has the same
  # simplified WBGT at REFERENCE_HUMIDITY when humidity or dew point is known
  def effective_temperature(temp, unit, humidity, dew_point)
    Humidity.check_inputs!(temp, humidity, dew_point)
    temp_c = temp && normalize_temperature(temp, unit)
    return temp_c if temp_c.nil? || (humidity.nil? && dew_point.nil?)

    Humidity.effective_temperature(temp_c, humidity: humidity,
                                           dew_point_c: dew_point && normalize_temperature(dew_point, unit))
  end

  def calculate_heat_penalty(temp_c, time_seconds)
    return 0.0 if temp_c.nil?

    data = FACTORS.fetch('heat')
    ideal_min, ideal_max = data.fetch('ideal_range_celsius')
    return 0.0 if temp_c.between?(ideal_min, ideal_max)

    points = data.fetch('data_points')
    base_penalty = interpolate_environmental_factor(points, temp_c)

    (base_penalty * duration_factor(time_seconds)).round(2)
  end

  def duration_factor(time_seconds)
    return 1.0 if time_seconds.nil?

    minutes = (time_seconds / 60.0).clamp(HEAT_DURATION_FACTORS.first.first, HEAT_DURATION_FACTORS.last.first)
    (from_minutes, from_factor), (to_minutes, to_factor) =
      HEAT_DURATION_FACTORS.each_cons(2).find { |_, (upper, _)| minutes <= upper }

    from_factor + (((minutes - from_minutes) / (to_minutes - from_minutes)) * (to_factor - from_factor))
  end

  def normalize_temperature(temp, unit)
    return temp.to_f if %i[c celsius].include?(unit.to_s.downcase.to_sym)
    return ((temp.to_f - 32) * 5.0 / 9.0).round(2) if %i[f fahrenheit].include?(unit.to_s.downcase.to_sym)

    raise ArgumentError, "Unsupported temperature unit '#{unit}'. Supported: :c, :f"
  end

  def calculate_altitude_penalty(alt)
    return 0.0 if alt.nil?

    data = FACTORS.fetch('altitude')
    threshold = data.fetch('threshold_meters')
    return 0.0 if alt <= threshold

    points = data.fetch('data_points')
    interpolate_environmental_factor(points, alt)
  end

  def interpolate_environmental_factor(points, value)
    key_map, sorted_floats = environmental_key_mapping(points)

    return points.fetch(key_map[sorted_floats.first]).to_f if value <= sorted_floats.first
    return points.fetch(key_map[sorted_floats.last]).to_f if value >= sorted_floats.last

    lower_val, upper_val = neighboring_environmental_points(sorted_floats, value)
    return points.fetch(key_map[lower_val]).to_f if lower_val == upper_val

    interpolate_values(points, key_map, lower_val, upper_val, value)
  end

  def environmental_key_mapping(points)
    map = points.keys.to_h { |k| [k.to_f, k] }
    [map, map.keys.sort]
  end

  def neighboring_environmental_points(sorted_floats, value)
    lower = sorted_floats.select { |k| k <= value }.max
    upper = sorted_floats.select { |k| k >= value }.min
    [lower, upper]
  end

  def interpolate_values(points, key_map, lower_val, upper_val, value)
    lower_factor = points.fetch(key_map[lower_val]).to_f
    upper_factor = points.fetch(key_map[upper_val]).to_f

    ratio = (value - lower_val) / (upper_val - lower_val)
    (lower_factor + ((upper_factor - lower_factor) * ratio)).round(2)
  end
end
