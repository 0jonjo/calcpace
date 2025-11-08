# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/calcpace'

# Test converter chain functionality
class TestConverterChain < Minitest::Test
  def setup
    @calc = Calcpace.new
  end

  def test_convert_chain_simple
    # 1 km to miles to feet
    result = @calc.convert_chain(1, [:km_to_mi, :mi_to_feet])
    assert_in_delta 3280.84, result, 0.01
  end

  def test_convert_chain_multiple_steps
    # 100 meters to km to miles to feet
    result = @calc.convert_chain(100, [:meters_to_km, :km_to_mi, :mi_to_feet])
    assert_in_delta 328.084, result, 0.01
  end

  def test_convert_chain_with_strings
    # 1 km using string format
    result = @calc.convert_chain(1, ['km to meters', 'meters to feet'])
    assert_in_delta 3280.84, result, 0.01
  end

  def test_convert_chain_speed_units
    # 10 m/s to km/h to mi/h
    result = @calc.convert_chain(10, [:m_s_to_km_h, :km_h_to_mi_h])
    assert_in_delta 22.3694, result, 0.01
  end

  def test_convert_chain_single_conversion
    # Chain with single conversion should work like regular convert
    result = @calc.convert_chain(1, [:km_to_mi])
    assert_equal @calc.convert(1, :km_to_mi), result
  end

  def test_convert_chain_empty_conversions
    # Empty conversions should return original value
    result = @calc.convert_chain(42, [])
    assert_equal 42, result
  end

  def test_convert_chain_negative_value_raises_error
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.convert_chain(-1, [:km_to_mi])
    end
  end

  def test_convert_chain_zero_value_raises_error
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.convert_chain(0, [:km_to_mi])
    end
  end

  def test_convert_chain_invalid_unit_raises_error
    assert_raises(Calcpace::UnsupportedUnitError) do
      @calc.convert_chain(1, [:km_to_mi, :invalid_unit])
    end
  end

  def test_convert_chain_with_description
    result = @calc.convert_chain_with_description(1, [:km_to_mi, :mi_to_feet])
    assert_kind_of Hash, result
    assert result.key?(:result)
    assert result.key?(:description)
    assert_in_delta 3280.84, result[:result], 0.01
    assert_includes result[:description], 'km_to_mi'
    assert_includes result[:description], 'mi_to_feet'
    assert_includes result[:description], '1'
  end

  def test_convert_chain_with_description_multiple_steps
    result = @calc.convert_chain_with_description(100, [:meters_to_km, :km_to_mi])
    assert_includes result[:description], '100'
    assert_includes result[:description], 'meters_to_km'
    assert_includes result[:description], 'km_to_mi'
    assert_in_delta 0.0621371, result[:result], 0.0001
  end

  # Practical examples
  def test_practical_marathon_distance_conversions
    # Marathon distance: 42.195 km to various units
    km_to_mi = @calc.convert_chain(42.195, [:km_to_mi])
    assert_in_delta 26.219, km_to_mi, 0.01

    km_to_feet = @calc.convert_chain(42.195, [:km_to_meters, :meters_to_feet])
    assert_in_delta 138_435, km_to_feet, 1
  end

  def test_practical_speed_conversions
    # Running speed: 3.5 m/s to various units
    result = @calc.convert_chain_with_description(3.5, [:m_s_to_km_h, :km_h_to_mi_h])
    # 3.5 m/s = 12.6 km/h = 7.83 mi/h
    assert_in_delta 7.83, result[:result], 0.01
  end
end
