# frozen_string_literal: true

require 'yaml'

# Module for adjusting race performance based on environmental conditions
#
# Scientific basis:
# - Heat: Matthew Ely et al. (2007) "Impact of Weather on Marathon-Running Performance"
# - Altitude: NCAA Altitude Adjustment Factors (TFRRS)
module EnvironmentalAdjuster
  DATA_PATH = File.expand_path('data/environmental_factors.yml', __dir__).freeze
  FACTORS = YAML.safe_load_file(DATA_PATH, permitted_classes: [], aliases: false).freeze

  # Calculates the performance penalty percentage for given environmental conditions
  #
  # @param temperature [Numeric, nil] ambient temperature
  # @param temperature_unit [Symbol, String] :c (Celsius) or :f (Fahrenheit)
  # @param altitude [Numeric, nil] altitude in meters
  # @param time_seconds [Numeric, nil] duration of the effort in seconds
  # @return [Hash] hash with :total_penalty_percent and breakdown in :factors
  def calculate_penalty(temperature: nil, temperature_unit: :c, altitude: nil, time_seconds: nil)
    heat_penalty = calculate_heat_penalty(temperature, temperature_unit, time_seconds)
    altitude_penalty = calculate_altitude_penalty(altitude)

    {
      total_penalty_percent: (heat_penalty + altitude_penalty).round(2),
      factors: {
        heat: heat_penalty,
        altitude: altitude_penalty
      }
    }
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

  def calculate_heat_penalty(temp, unit, time_seconds)
    return 0.0 if temp.nil?

    temp_c = normalize_temperature(temp, unit)

    data = FACTORS.fetch('heat')
    ideal_min, ideal_max = data.fetch('ideal_range_celsius')
    return 0.0 if temp_c.between?(ideal_min, ideal_max)

    points = data.fetch('data_points')
    base_penalty = interpolate_environmental_factor(points, temp_c)

    (base_penalty * duration_factor(time_seconds)).round(2)
  end

  def duration_factor(time_seconds)
    return 1.0 if time_seconds.nil?

    minutes = time_seconds / 60.0

    # Rule based on Matthew Ely (2007) heat degradation curve.
    # Scaled for piecewise linear interpolation to avoid jumps.
    if minutes <= 30
      0.5
    elsif minutes <= 60
      # Scale from 0.5x (30m) up to 1.0x (60m)
      0.5 + (((minutes - 30.0) / 30.0) * 0.5)
    elsif minutes <= 180
      # Scale from 1.0x (60m) up to 3.0x (180m / 3h)
      1.0 + (((minutes - 60.0) / 120.0) * 2.0)
    else
      # Scale from 3.0x (3h) up to 4.5x (4h)
      capped_minutes = [minutes, 240.0].min
      3.0 + (((capped_minutes - 180.0) / 60.0) * 1.5)
    end
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
