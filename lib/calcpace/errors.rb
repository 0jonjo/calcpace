# frozen_string_literal: true

# Calcpace custom error classes for better error handling
class Calcpace
  # Base error class for all Calcpace errors
  class Error < StandardError; end

  # Raised when time string format is invalid
  # Expected formats: HH:MM:SS or MM:SS
  class InvalidTimeFormatError < Error
    def initialize(msg = 'Invalid time format. Expected HH:MM:SS or MM:SS format.')
      super
    end
  end

  # Raised when a numeric input is not positive (zero or negative)
  class NonPositiveInputError < Error
    def initialize(msg = 'Input must be a positive number.')
      super
    end
  end

  # Raised when versioned/static gem data fails an internal consistency check
  class InvalidDataError < Error; end

  # Raised when an unsupported unit or unit conversion is requested
  #
  # @example conversion pair
  #   raise UnsupportedUnitError, :km_to_furlong
  # @example single unit, with the supported ones listed
  #   raise UnsupportedUnitError.new(:furlong, supported: %i[km mi])
  class UnsupportedUnitError < Error
    def initialize(unit = nil, supported: nil)
      super(build_message(unit, supported))
    end

    private

    def build_message(unit, supported)
      return conversion_message(unit) unless supported

      "Unsupported unit: #{unit.inspect}. Supported units: #{supported.map(&:inspect).join(', ')}"
    end

    def conversion_message(unit)
      unit ? "Unsupported unit conversion: #{unit}" : 'Unsupported unit conversion'
    end
  end
end
