# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/calcpace'

class TestConverter < Minitest::Test
  def setup
    @calc = Calcpace.new
  end

  def test_convert_to_seconds
    assert_equal 4262, @calc.convert_to_seconds('01:11:02')
    assert_equal 120, @calc.convert_to_seconds('02:00')
  end

  def test_convert_to_clocktime
    assert_equal '01:11:02', @calc.convert_to_clocktime(4262)
  end

  def test_convert_to_clocktime_more_than_24_hours
    assert_equal '1 03:46:40', @calc.convert_to_clocktime(100_000)
  end

  def test_convert_distance_one
    assert_equal 0.621371, @calc.convert(1, :km_to_mi)
    assert_equal 1.60934, @calc.convert(1, :mi_to_km)
    assert_equal 1.852, @calc.convert(1, :nautical_mi_to_km)
    assert_equal 0.539957, @calc.convert(1, :km_to_nautical_mi)
    assert_equal 0.001, @calc.convert(1, :meters_to_km)
    assert_equal 1000, @calc.convert(1, :km_to_meters)
  end

  def test_convert_distance_two
    assert_equal 0.000621371, @calc.convert(1, :meters_to_mi)
    assert_equal 1609.34, @calc.convert(1, :mi_to_meters)
    assert_equal 3.28084, @calc.convert(1, :meters_to_feet)
    assert_equal 0.3048, @calc.convert(1, :feet_to_meters)
    assert_equal 1.09361, @calc.convert(1, :meters_to_yards)
  end

  def test_convert_distance_three
    assert_equal 0.9144, @calc.convert(1, :yards_to_meters)
    assert_equal 39.3701, @calc.convert(1, :meters_to_inches)
    assert_equal 0.0254, @calc.convert(1, :inches_to_meters)
  end

  def test_convert_velocity_one
    assert_equal 3.60, @calc.convert(1, :m_s_to_km_h)
    assert_equal 0.277778, @calc.convert(1, :km_h_to_m_s)
    assert_equal 2.23694, @calc.convert(1, :m_s_to_mi_h)
    assert_equal 0.44704, @calc.convert(1, :mi_h_to_m_s)
    assert_equal 1.94384, @calc.convert(1, :m_s_to_nautical_mi_h)
  end

  def test_convert_velocity_two
    assert_equal 0.514444, @calc.convert(1, :nautical_mi_h_to_m_s)
    assert_equal 0.621371, @calc.convert(1, :km_h_to_mi_h)
    assert_equal 1.60934, @calc.convert(1, :mi_h_to_km_h)
    assert_equal 1.94384, @calc.convert(1, :m_s_to_knots)
    assert_equal 0.514444, @calc.convert(1, :knots_to_m_s)
  end

  def test_convert_with_string
    assert_equal 0.621371, @calc.convert(1, 'km to mi')
  end

  def test_constant
    assert_equal 0.621371, @calc.constant(:km_to_mi)
    assert_equal 1.60934, @calc.constant('mi to km')
    assert_equal 1.852, @calc.constant('nautical mi to km')
  end

  def test_list_all
    assert_kind_of Hash, @calc.list_all
    assert_equal 42, @calc.list_all.size
  end

  def test_list_speed
    assert_kind_of Hash, @calc.list_speed
    assert_equal 16, @calc.list_speed.size
  end

  def test_list_distance_constants
    assert_kind_of Hash, @calc.list_distance
    assert_equal 26, @calc.list_distance.size
  end

  def test_list_content
    assert_equal 'KM to MI', @calc.list_all[:km_to_mi]
  end
end
