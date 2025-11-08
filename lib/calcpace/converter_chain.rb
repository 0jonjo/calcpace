# frozen_string_literal: true

# Module for chaining multiple unit conversions
#
# This module allows performing multiple conversions in sequence,
# which is useful for complex unit transformations.
module ConverterChain
  # Performs a chain of conversions on a value
  #
  # @param value [Numeric] the initial value to convert
  # @param conversions [Array<Symbol, String>] array of conversion units
  # @return [Float] the final converted value
  # @raise [Calcpace::NonPositiveInputError] if value is not positive
  # @raise [Calcpace::UnsupportedUnitError] if any conversion unit is not supported
  #
  # @example Convert kilometers to miles to feet
  #   convert_chain(1, [:km_to_mi, :mi_to_feet])
  #   #=> 3280.84 (1 km = 0.621 mi = 3280.84 feet)
  #
  # @example Using string format
  #   convert_chain(100, ['meters to km', 'km to mi'])
  #   #=> 0.0621371 (100 m = 0.1 km = 0.0621 mi)
  def convert_chain(value, conversions)
    check_positive(value, 'Value')
    conversions.reduce(value) do |result, conversion|
      result * constant(conversion)
    end
  end

  # Performs a chain of conversions and returns a description
  #
  # @param value [Numeric] the initial value to convert
  # @param conversions [Array<Symbol, String>] array of conversion units
  # @return [Hash] hash with :result and :description keys
  #
  # @example
  #   convert_chain_with_description(1, [:km_to_mi, :mi_to_feet])
  #   #=> { result: 3280.84, description: "1.0 → km_to_mi → mi_to_feet → 3280.84" }
  def convert_chain_with_description(value, conversions)
    initial_value = value
    result = convert_chain(value, conversions)
    conversion_names = conversions.map(&:to_s).join(' → ')
    description = "#{initial_value} → #{conversion_names} → #{result.round(4)}"

    { result: result, description: description }
  end
end
