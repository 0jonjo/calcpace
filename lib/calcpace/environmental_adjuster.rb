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
  # @param humidity [Numeric, nil] relative humidity percentage (reserved for future use)
  # @param altitude [Numeric, nil] altitude in meters
  # @return [Hash] hash with :total_penalty_percent and breakdown in :factors
  def calculate_penalty(temperature: nil, temperature_unit: :c, humidity: nil, altitude: nil)
    heat_penalty = calculate_heat_penalty(temperature, temperature_unit)
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
  # @param temperature [Numeric, nil] ambient temperature
  # @param temperature_unit [Symbol, String] :c (Celsius) or :f (Fahrenheit)
  # @param humidity [Numeric, nil] relative humidity percentage
  # @param altitude [Numeric, nil] altitude in meters
  # @return [Hash] hash with adjusted time and penalty details
  def adjust_time(time_seconds, temperature: nil, temperature_unit: :c, humidity: nil, altitude: nil)
    penalty = calculate_penalty(temperature: temperature, temperature_unit: temperature_unit,
                                humidity: humidity, altitude: altitude)
    percent = penalty[:total_penalty_percent]
    adjusted_seconds = time_seconds * (1 + (percent / 100.0))

    {
      original_time: time_seconds,
      adjusted_time: adjusted_seconds.round(2),
      adjusted_time_clock: convert_to_clocktime(adjusted_seconds),
      penalty_percent: percent,
      factors: penalty[:factors]
    }
  end

  private

  def calculate_heat_penalty(temp, unit)
    return 0.0 if temp.nil?

    temp_c = normalize_temperature(temp, unit)

    data = FACTORS.fetch('heat')
    ideal_min, ideal_max = data.fetch('ideal_range_celsius')
    return 0.0 if temp_c >= ideal_min && temp_c <= ideal_max

    points = data.fetch('data_points')
    interpolate_environmental_factor(points, temp_c)
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
    # Create a map of float values to original keys for robust lookup
    key_map = points.keys.each_with_object({}) { |k, h| h[k.to_f] = k }
    sorted_floats = key_map.keys.sort

    return points.fetch(key_map[sorted_floats.first]).to_f if value <= sorted_floats.first
    return points.fetch(key_map[sorted_floats.last]).to_f if value >= sorted_floats.last

    lower_val = sorted_floats.select { |k| k <= value }.max
    upper_val = sorted_floats.select { |k| k >= value }.min

    return points.fetch(key_map[lower_val]).to_f if lower_val == upper_val

    lower_factor = points.fetch(key_map[lower_val]).to_f
    upper_factor = points.fetch(key_map[upper_val]).to_f

    ratio = (value - lower_val) / (upper_val - lower_val)
    (lower_factor + ((upper_factor - lower_factor) * ratio)).round(2)
  end
end
