# frozen_string_literal: true

# Module for converting pace between different distance units
#
# This module provides methods to convert running pace between kilometers
# and miles, maintaining the time per distance unit format.
module PaceConverter
  # Converts pace from one unit to another
  #
  # The pace comes back in the same two formats #convert_to_clocktime offers:
  # the padded HH:MM:SS by default, and the compact display format a runner
  # reads on a screen with <tt>compact: true</tt>.
  #
  # @param pace [Numeric, String] pace in seconds per unit or time string (MM:SS)
  # @param conversion [Symbol, String] conversion type (:km_to_mi, :mi_to_km, 'km to mi', 'mi to km')
  # @param compact [Boolean] when true, return the compact display format
  # @return [String] converted pace in HH:MM:SS format, or 'M:SS' / 'H:MM:SS' with compact: true
  # @raise [ArgumentError] if conversion type is not supported
  # @raise [Calcpace::NonPositiveInputError] if pace is not positive
  #
  # @example padded (default)
  #   convert_pace('05:00', :km_to_mi)    #=> '00:08:02' (5:00/km = 8:02/mi)
  #   convert_pace('08:00', :mi_to_km)    #=> '00:04:58' (8:00/mi ≈ 4:58/km)
  #   convert_pace(300, 'km to mi')       #=> '00:08:02' (300s/km = 482s/mi)
  #
  # @example compact
  #   convert_pace('05:00', :km_to_mi, compact: true)  #=> '8:02'
  #   convert_pace(300, 'km to mi', compact: true)     #=> '8:02'
  def convert_pace(pace, conversion, compact: false)
    pace_seconds = pace.is_a?(String) ? convert_to_seconds(pace) : pace
    check_positive(pace_seconds, 'Pace')

    conversion_type = normalize_conversion(conversion)
    converted_seconds = apply_pace_conversion(pace_seconds, conversion_type)

    convert_to_clocktime(converted_seconds, compact: compact)
  end

  # Converts pace from kilometers to miles
  #
  # @param pace_per_km [Numeric, String] pace in seconds per km or time string (MM:SS)
  # @param compact [Boolean] when true, return the compact display format
  # @return [String] pace per mile in HH:MM:SS format, or 'M:SS' / 'H:MM:SS' with compact: true
  #
  # @example
  #   pace_km_to_mi('05:00')                #=> '00:08:02' (5:00/km = 8:02/mi)
  #   pace_km_to_mi(300)                    #=> '00:08:02' (300s/km = 482s/mi)
  #   pace_km_to_mi('05:00', compact: true) #=> '8:02'
  def pace_km_to_mi(pace_per_km, compact: false)
    convert_pace(pace_per_km, :km_to_mi, compact: compact)
  end

  # Converts pace from miles to kilometers
  #
  # @param pace_per_mi [Numeric, String] pace in seconds per mile or time string (MM:SS)
  # @param compact [Boolean] when true, return the compact display format
  # @return [String] pace per kilometer in HH:MM:SS format, or 'M:SS' / 'H:MM:SS' with compact: true
  #
  # @example
  #   pace_mi_to_km('08:00')                #=> '00:04:58' (8:00/mi ≈ 4:58/km)
  #   pace_mi_to_km(480)                    #=> '00:04:58' (480s/mi = 298s/km)
  #   pace_mi_to_km('08:00', compact: true) #=> '4:58'
  def pace_mi_to_km(pace_per_mi, compact: false)
    convert_pace(pace_per_mi, :mi_to_km, compact: compact)
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
      pace_seconds * Converter::Distance::MI_TO_KM
    when :mi_to_km
      # If running at X seconds per mile, pace per km = X / (miles to km ratio)
      pace_seconds * Converter::Distance::KM_TO_MI
    end
  end
end
