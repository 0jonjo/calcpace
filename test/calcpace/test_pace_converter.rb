# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/calcpace'

# Test pace converter functionality
class TestPaceConverter < Minitest::Test
  def setup
    @calc = Calcpace.new
  end

  # Test convert_pace method with km to mi
  def test_convert_pace_km_to_mi_with_string
    # 5:00/km should be approximately 8:02/mi
    result = @calc.convert_pace('05:00', :km_to_mi)
    assert_equal '00:08:02', result
  end

  def test_convert_pace_km_to_mi_with_numeric
    # 300 seconds/km (5:00/km) should be approximately 483 seconds/mi (8:02/mi)
    result = @calc.convert_pace(300, :km_to_mi)
    assert_equal '00:08:02', result
  end

  def test_convert_pace_km_to_mi_string_format
    # Test with string format 'km to mi'
    result = @calc.convert_pace('05:00', 'km to mi')
    assert_equal '00:08:02', result
  end

  # Test convert_pace method with mi to km
  def test_convert_pace_mi_to_km_with_string
    # 8:00/mi should be approximately 4:58/km
    result = @calc.convert_pace('08:00', :mi_to_km)
    assert_equal '00:04:58', result
  end

  def test_convert_pace_mi_to_km_with_numeric
    # 480 seconds/mi (8:00/mi) should be approximately 298 seconds/km (4:58/km)
    result = @calc.convert_pace(480, :mi_to_km)
    assert_equal '00:04:58', result
  end

  def test_convert_pace_mi_to_km_string_format
    # Test with string format 'mi to km'
    result = @calc.convert_pace('08:00', 'mi to km')
    assert_equal '00:04:58', result
  end

  # Test pace_km_to_mi convenience method
  def test_pace_km_to_mi_with_string
    result = @calc.pace_km_to_mi('05:00')
    assert_equal '00:08:02', result
  end

  def test_pace_km_to_mi_with_numeric
    result = @calc.pace_km_to_mi(300)
    assert_equal '00:08:02', result
  end

  def test_pace_km_to_mi_fast_pace
    # 3:30/km should be approximately 5:37/mi
    result = @calc.pace_km_to_mi('03:30')
    assert_equal '00:05:37', result
  end

  def test_pace_km_to_mi_slow_pace
    # 7:00/km should be approximately 11:15/mi
    result = @calc.pace_km_to_mi('07:00')
    assert_equal '00:11:15', result
  end

  # Test pace_mi_to_km convenience method
  def test_pace_mi_to_km_with_string
    result = @calc.pace_mi_to_km('08:00')
    assert_equal '00:04:58', result
  end

  def test_pace_mi_to_km_with_numeric
    result = @calc.pace_mi_to_km(480)
    assert_equal '00:04:58', result
  end

  def test_pace_mi_to_km_fast_pace
    # 6:00/mi should be approximately 3:43/km
    result = @calc.pace_mi_to_km('06:00')
    assert_equal '00:03:43', result
  end

  def test_pace_mi_to_km_slow_pace
    # 10:00/mi should be approximately 6:12/km
    result = @calc.pace_mi_to_km('10:00')
    assert_equal '00:06:12', result
  end

  # Test reciprocal conversions (should get approximately back to original)
  def test_reciprocal_conversion_km_mi_km
    original = '05:00'
    to_mi = @calc.pace_km_to_mi(original)
    back_to_km = @calc.pace_mi_to_km(to_mi)
    # Due to rounding, we might be off by 1 second
    assert_match(/00:04:59|00:05:00/, back_to_km)
  end

  def test_reciprocal_conversion_mi_km_mi
    original = '08:00'
    to_km = @calc.pace_mi_to_km(original)
    back_to_mi = @calc.pace_km_to_mi(to_km)
    # Due to rounding, we might be off by 1 second
    assert_match(/00:07:59|00:08:00/, back_to_mi)
  end

  # Test error handling
  def test_convert_pace_with_negative_value
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.convert_pace(-300, :km_to_mi)
    end
  end

  def test_convert_pace_with_zero
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.convert_pace(0, :km_to_mi)
    end
  end

  def test_convert_pace_with_invalid_conversion
    error = assert_raises(ArgumentError) do
      @calc.convert_pace('05:00', :invalid_conversion)
    end
    assert_match(/Unsupported pace conversion/, error.message)
  end

  def test_pace_km_to_mi_with_negative_value
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.pace_km_to_mi(-300)
    end
  end

  def test_pace_mi_to_km_with_negative_value
    assert_raises(Calcpace::NonPositiveInputError) do
      @calc.pace_mi_to_km(-480)
    end
  end

  # Test edge cases
  def test_convert_pace_very_fast
    # 2:30/km should be approximately 4:01/mi
    result = @calc.pace_km_to_mi('02:30')
    assert_equal '00:04:01', result
  end

  def test_convert_pace_very_slow
    # 10:00/km should be approximately 16:05/mi
    result = @calc.pace_km_to_mi('10:00')
    assert_equal '00:16:05', result
  end

  def test_convert_pace_with_hours
    # 1:00:00/km (extremely slow, but valid input)
    result = @calc.pace_km_to_mi('01:00:00')
    assert_equal '01:36:33', result
  end
end
