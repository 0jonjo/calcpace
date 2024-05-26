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

  def test_convert_distance_km
    assert_equal 6.21, @checker.convert_distance(10, 'km')
    assert_equal 16.09, @checker.convert_distance(10, 'mi')
    assert_raises(RuntimeError) { @checker.convert_distance(10, 'invalid') }
  end
end
