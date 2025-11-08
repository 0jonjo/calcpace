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

  # Raised when an unsupported unit conversion is requested
  class UnsupportedUnitError < Error
    def initialize(unit = nil)
      msg = unit ? "Unsupported unit conversion: #{unit}" : 'Unsupported unit conversion'
      super(msg)
    end
  end
end
