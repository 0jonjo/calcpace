# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/calcpace'

class TestConverter < Minitest::Test
  def setup
    @checker = Calcpace.new
  end

  def test_convert_to_seconds
    assert_equal 4262, @checker.convert_to_seconds('01:11:02')
  end

  def test_convert_to_clocktime
    assert_equal '01:11:02', @checker.convert_to_clocktime(4262)
  end

  def test_convert_distance_one
    assert_equal 0.621371, @checker.convert(1, :km_to_mi)
    assert_equal 1.60934, @checker.convert(1, :mi_to_km)
    assert_equal 1.852, @checker.convert(1, :nautical_mi_to_km)
    assert_equal 0.539957, @checker.convert(1, :km_to_nautical_mi)
    assert_equal 0.001, @checker.convert(1, :meters_to_km)
    assert_equal 1000, @checker.convert(1, :km_to_meters)
  end

  def test_convert_distance_two
    assert_equal 0.000621371, @checker.convert(1, :meters_to_mi)
    assert_equal 1609.34, @checker.convert(1, :mi_to_meters)
    assert_equal 3.28084, @checker.convert(1, :meters_to_feet)
    assert_equal 0.3048, @checker.convert(1, :feet_to_meters)
    assert_equal 1.09361, @checker.convert(1, :meters_to_yards)
  end

  def test_convert_distance_three
    assert_equal 0.9144, @checker.convert(1, :yards_to_meters)
    assert_equal 39.3701, @checker.convert(1, :meters_to_inches)
    assert_equal 0.0254, @checker.convert(1, :inches_to_meters)
  end

  def test_convert_velocity_one
    assert_equal 3.60, @checker.convert(1, :m_s_to_km_h)
    assert_equal 0.277778, @checker.convert(1, :km_h_to_m_s)
    assert_equal 2.23694, @checker.convert(1, :m_s_to_mi_h)
    assert_equal 0.44704, @checker.convert(1, :mi_h_to_m_s)
    assert_equal 1.94384, @checker.convert(1, :m_s_to_nautical_mi_h)
  end

  def test_convert_velocity_two
    assert_equal 0.514444, @checker.convert(1, :nautical_mi_h_to_m_s)
    assert_equal 0.621371, @checker.convert(1, :km_h_to_mi_h)
    assert_equal 1.60934, @checker.convert(1, :mi_h_to_km_h)
    assert_equal 1.94384, @checker.convert(1, :m_s_to_knots)
    assert_equal 0.514444, @checker.convert(1, :knots_to_m_s)
  end

  def test_constant
    assert_equal 0.621371, @checker.constant(:km_to_mi)
    assert_equal 1.60934, @checker.constant(:mi_to_km)
    assert_equal 1.852, @checker.constant(:nautical_mi_to_km)
  end

  def test_list_all
    assert_equal 26, @checker.list_all.size
  end

  def test_list_speed
    assert_equal 12, @checker.list_speed.size
  end

  def test_list_distance_constants
    assert_equal 14, @checker.list_distance.size
  end
end
