# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/calcpace'

class TestConverter < Minitest::Test
  def setup
    @checker = Calcpace.new
    @checker_bigdecimal = Calcpace.new(true)
  end

  def test_convert_to_seconds
    assert_equal 4262, @checker.convert_to_seconds('01:11:02')
  end

  def test_convert_to_clocktime
    assert_equal '01:11:02', @checker.convert_to_clocktime(4262)
  end

  def test_convert_distance
    assert_equal 0.621371, @checker.convert(1, 'KM_TO_MI')
    assert_equal 1.60934, @checker.convert(1, 'MI_TO_KM')
    assert_equal 1.852, @checker.convert(1, 'NAUTICAL_MI_TO_KM')
    assert_equal 0.539957, @checker.convert(1, 'KM_TO_NAUTICAL_MI')
    assert_equal 0.001, @checker.convert(1, 'METERS_TO_KM')
    assert_equal 1000, @checker.convert(1, 'KM_TO_METERS')
    assert_equal 0.000621371, @checker.convert(1, 'METERS_TO_MI')
    assert_equal 1609.34, @checker.convert(1, 'MI_TO_METERS')
    assert_equal 3.28084, @checker.convert(1, 'METERS_TO_FEET')
    assert_equal 0.3048, @checker.convert(1, 'FEET_TO_METERS')
    assert_equal 1.09361, @checker.convert(1, 'METERS_TO_YARDS')
    assert_equal 0.9144, @checker.convert(1, 'YARDS_TO_METERS')
    assert_equal 39.3701, @checker.convert(1, 'METERS_TO_INCHES')
    assert_equal 0.0254, @checker.convert(1, 'INCHES_TO_METERS')
  end

  def test_convert_velocity
    assert_equal 3.60, @checker.convert(1, 'M_S_TO_KM_H')
    assert_equal 0.277778, @checker.convert(1, 'KM_H_TO_M_S')
    assert_equal 2.23694, @checker.convert(1, 'M_S_TO_MI_H')
    assert_equal 0.44704, @checker.convert(1, 'MI_H_TO_M_S')
    assert_equal 1.94384, @checker.convert(1, 'M_S_TO_NAUTICAL_MI_H')
    assert_equal 0.514444, @checker.convert(1, 'NAUTICAL_MI_H_TO_M_S')
    assert_equal 0.621371, @checker.convert(1, 'KM_H_TO_MI_H')
    assert_equal 1.60934, @checker.convert(1, 'MI_H_TO_KM_H')
    assert_equal 1.94384, @checker.convert(1, 'M_S_TO_KNOTS')
    assert_equal 0.514444, @checker.convert(1, 'KNOTS_TO_M_S')
  end

  def test_convert_to_bigdecimal_or_float
    assert_equal 1.0, @checker.convert_to_bigdecimal_or_float(1)
    assert_equal 1.0, @checker.convert_to_bigdecimal_or_float(1.0)
    assert_equal BigDecimal('1.0'), @checker_bigdecimal.convert_to_bigdecimal_or_float(1)
    assert_equal BigDecimal('1.0'), @checker_bigdecimal.convert_to_bigdecimal_or_float(1.0)
  end

  def test_constant
    assert_equal 0.621371, @checker.constant('KM_TO_MI')
    assert_equal 1.60934, @checker.constant('MI_TO_KM')
    assert_equal 1.852, @checker.constant('NAUTICAL_MI_TO_KM')
  end

  def test_list_constants
    assert_equal 26, @checker.list_constants.size
  end
end
