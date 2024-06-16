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

  def test_to_seconds
    assert_equal 3600, @checker.to_seconds('01:00:00')
    assert_raises(RuntimeError) { @checker.to_seconds('invalid') }
  end

  def test_convert_to_clocktime
    assert_equal '01:11:02', @checker.convert_to_clocktime(4262)
  end

  def test_to_clocktime
    assert_equal '01:00:00', @checker.to_clocktime(3600)
    assert_equal '02 01:00:00', @checker.to_clocktime(90000)
    assert_raises(RuntimeError) { @checker.to_clocktime(-1) }
    assert_raises(RuntimeError) { @checker.to_clocktime(0) }
    assert_raises(RuntimeError) { @checker.to_clocktime('invalid') }
  end

  def test_convert_the_distance
    assert_equal 6.21, @checker.convert_the_distance(10, 'km')
    assert_equal 6.2, @checker.convert_the_distance(10, 'km', 1)
    assert_equal 6.214, @checker.convert_the_distance(10, 'km', 3)
    assert_equal 16.09, @checker.convert_the_distance(10, 'mi')
  end

  def test_convert
    assert_equal 6.21, @checker.convert(10, 'km')
    assert_equal 16.09, @checker.convert(10, 'mi')
    assert_equal 6.2, @checker.convert(10, 'km', 1)
    assert_raises(RuntimeError) { @checker.convert(10, 'invalid') }
    assert_raises(RuntimeError) { @checker.convert(-1, 'km') }
    assert_raises(RuntimeError) { @checker.convert(10, 'km', -2) }
    assert_raises(RuntimeError) { @checker.convert(10, 'km', 0) }
    assert_raises(RuntimeError) { @checker.convert(10, 'km', 'invalid') }
  end
end
