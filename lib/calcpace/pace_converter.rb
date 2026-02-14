# frozen_string_literal: true

# Module for converting pace between different distance units
#
# This module provides methods to convert running pace between kilometers
# and miles, maintaining the time per distance unit format.
module PaceConverter
  # Conversion factor: 1 mile = 1.60934 kilometers
  MI_TO_KM = 1.60934
  KM_TO_MI = 0.621371

  # Converts pace from one unit to another
  #
  # @param pace [Numeric, String] pace in seconds per unit or time string (MM:SS)
  # @param conversion [Symbol, String] conversion type (:km_to_mi, :mi_to_km, 'km to mi', 'mi to km')
  # @return [String] converted pace in MM:SS format
  # @raise [ArgumentError] if conversion type is not supported
  # @raise [Calcpace::NonPositiveInputError] if pace is not positive
  #
  # @example
  #   convert_pace('05:00', :km_to_mi)    #=> '08:02' (5:00/km = 8:02/mi)
  #   convert_pace('08:00', :mi_to_km)    #=> '04:58' (8:00/mi ≈ 4:58/km)
  #   convert_pace(300, 'km to mi')       #=> '08:02' (300s/km = 482s/mi)
  def convert_pace(pace, conversion)
    pace_seconds = pace.is_a?(String) ? convert_to_seconds(pace) : pace
    check_positive(pace_seconds, 'Pace')

    conversion_type = normalize_conversion(conversion)
    converted_seconds = apply_pace_conversion(pace_seconds, conversion_type)

    convert_to_clocktime(converted_seconds)
  end

  # Converts pace from kilometers to miles
  #
  # @param pace_per_km [Numeric, String] pace in seconds per km or time string (MM:SS)
  # @return [String] pace per mile in MM:SS format
  #
  # @example
  #   pace_km_to_mi('05:00')  #=> '08:02' (5:00/km = 8:02/mi)
  #   pace_km_to_mi(300)      #=> '08:02' (300s/km = 482s/mi)
  def pace_km_to_mi(pace_per_km)
    convert_pace(pace_per_km, :km_to_mi)
  end

  # Converts pace from miles to kilometers
  #
  # @param pace_per_mi [Numeric, String] pace in seconds per mile or time string (MM:SS)
  # @return [String] pace per kilometer in MM:SS format
  #
  # @example
  #   pace_mi_to_km('08:00')  #=> '04:58' (8:00/mi ≈ 4:58/km)
  #   pace_mi_to_km(480)      #=> '04:58' (480s/mi = 298s/km)
  def pace_mi_to_km(pace_per_mi)
    convert_pace(pace_per_mi, :mi_to_km)
  end

  private

  # Normalizes conversion string/symbol to standard format
  #
  # @param conversion [Symbol, String] conversion type
  # @return [Symbol] normalized conversion symbol
  # @raise [ArgumentError] if conversion type is not supported
  def normalize_conversion(conversion)
    normalized = if conversion.is_a?(String)
                   conversion.downcase.gsub(/\s+/, '_').to_sym
                 else
                   conversion.to_sym
                 end

    unless %i[km_to_mi mi_to_km].include?(normalized)
      raise ArgumentError,
            "Unsupported pace conversion: #{conversion}. " \
            "Supported conversions: km_to_mi, mi_to_km"
    end

    normalized
  end

  # Applies the pace conversion
  #
  # @param pace_seconds [Numeric] pace in seconds
  # @param conversion_type [Symbol] conversion type (:km_to_mi or :mi_to_km)
  # @return [Float] converted pace in seconds
  def apply_pace_conversion(pace_seconds, conversion_type)
    case conversion_type
    when :km_to_mi
      # If running at X seconds per km, pace per mile = X * (miles to km ratio)
      pace_seconds * MI_TO_KM
    when :mi_to_km
      # If running at X seconds per mile, pace per km = X / (miles to km ratio)
      pace_seconds * KM_TO_MI
    end
  end
end
