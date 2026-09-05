# frozen_string_literal: true

require_relative '../test_helper'

# Tests for StrideCalculator module — stride length from pace and cadence
class TestStrideCalculator < CalcpaceTest
  # --- stride_length ---
  def test_stride_length_documented_example
    # 5:00/km = 300 s/km → 200 m/min; 200 / 170 spm = 1.18 m per step
    assert_in_delta 1.18, @calc.stride_length('05:00', 170)
  end

  def test_stride_length_for_a_faster_runner
    # 4:00/km = 240 s/km → 250 m/min; 250 / 180 spm = 1.39 m per step
    assert_in_delta 1.39, @calc.stride_length('04:00', 180)
  end

  def test_stride_length_is_rounded_to_two_decimals
    stride = @calc.stride_length('05:00', 170)

    assert_kind_of Float, stride
    assert_equal stride.round(2), stride
  end

  def test_stride_length_accepts_numeric_pace_in_seconds
    assert_in_delta @calc.stride_length('05:00', 170), @calc.stride_length(300, 170)
  end

  def test_stride_length_accepts_hh_mm_ss_clock_pace
    assert_in_delta @calc.stride_length('05:00', 170), @calc.stride_length('00:05:00', 170)
  end

  def test_stride_length_accepts_float_cadence
    # 200 m/min / 172.5 spm = 1.159… → 1.16
    assert_in_delta 1.16, @calc.stride_length(300, 172.5)
  end

  def test_stride_length_per_mile_matches_the_equivalent_km_pace
    # 8:02/mi is the mile equivalent of 5:00/km, so the stride is the same
    assert_in_delta @calc.stride_length('05:00', 170),
                    @calc.stride_length('08:02', 170, unit: :mi),
                    0.01
  end

  def test_stride_length_per_mile_documented_example
    assert_in_delta 1.18, @calc.stride_length('08:02', 170, unit: :mi)
  end

  def test_stride_length_uses_the_exact_international_mile
    expected = (Converter::Distance::MI_TO_METERS / 482 * 60.0 / 170).round(2)

    assert_in_delta expected, @calc.stride_length(482, 170, unit: :mi)
  end

  def test_stride_length_accepts_unit_as_a_string
    assert_in_delta @calc.stride_length('05:00', 170, unit: :km),
                    @calc.stride_length('05:00', 170, unit: 'km')
  end

  def test_stride_length_grows_as_cadence_falls
    assert_operator @calc.stride_length(300, 160), :>, @calc.stride_length(300, 190)
  end

  # --- cadence_for_stride ---
  def test_cadence_for_stride_documented_example
    # 5:00/km → 200 m/min; 200 / 1.18 m = 169.5 spm
    assert_in_delta 169.5, @calc.cadence_for_stride('05:00', 1.18)
  end

  def test_cadence_for_stride_second_documented_example
    # 5:30/km → 181.81 m/min; 181.81 / 1.15 m = 158.1 spm
    assert_in_delta 158.1, @calc.cadence_for_stride('05:30', 1.15)
  end

  def test_cadence_for_stride_is_rounded_to_one_decimal
    cadence = @calc.cadence_for_stride('05:00', 1.18)

    assert_kind_of Float, cadence
    assert_equal cadence.round(1), cadence
  end

  def test_cadence_for_stride_accepts_numeric_pace_in_seconds
    assert_in_delta @calc.cadence_for_stride('05:00', 1.18), @calc.cadence_for_stride(300, 1.18)
  end

  def test_cadence_for_stride_per_mile_matches_the_equivalent_km_pace
    assert_in_delta @calc.cadence_for_stride('05:00', 1.18),
                    @calc.cadence_for_stride('08:02', 1.18, unit: :mi),
                    0.5
  end

  # A stride rounded to the centimetre is up to 0.005 m away from the exact one,
  # which is ~0.45% of a 1.11 m stride — so the cadence it comes back as can miss
  # by up to ~0.8 spm. The round trip is exact in the maths, not in the rounding.
  def test_cadence_for_stride_round_trips_with_stride_length
    stride = @calc.stride_length(300, 180)

    assert_in_delta 180, @calc.cadence_for_stride(300, stride), 1.0
  end

  def test_stride_length_round_trips_with_cadence_for_stride
    cadence = @calc.cadence_for_stride(330, 1.15)

    assert_in_delta 1.15, @calc.stride_length(330, cadence), 0.01
  end

  def test_round_trip_holds_in_miles_too
    stride = @calc.stride_length('07:00', 176, unit: :mi)

    assert_in_delta 176, @calc.cadence_for_stride('07:00', stride, unit: :mi), 1.0
  end

  # --- errors ---
  def test_stride_length_rejects_zero_cadence
    assert_error_with_message(Calcpace::NonPositiveInputError, 'Cadence') do
      @calc.stride_length('05:00', 0)
    end
  end

  def test_stride_length_rejects_negative_cadence
    assert_error_with_message(Calcpace::NonPositiveInputError, 'Cadence') do
      @calc.stride_length('05:00', -170)
    end
  end

  def test_stride_length_rejects_non_positive_pace
    assert_error_with_message(Calcpace::NonPositiveInputError, 'Pace') do
      @calc.stride_length(0, 170)
    end
  end

  def test_stride_length_rejects_an_invalid_pace_string
    # Same treatment convert_pace gives it: an unparseable clock is zero seconds
    assert_raises(Calcpace::NonPositiveInputError) { @calc.stride_length('not a pace', 170) }
  end

  def test_stride_length_rejects_an_unsupported_unit
    error = assert_raises(Calcpace::UnsupportedUnitError) { @calc.stride_length('05:00', 170, unit: :furlong) }

    assert_includes error.message, 'furlong'
  end

  def test_cadence_for_stride_rejects_zero_stride
    assert_error_with_message(Calcpace::NonPositiveInputError, 'Stride') do
      @calc.cadence_for_stride('05:00', 0)
    end
  end

  def test_cadence_for_stride_rejects_negative_stride
    assert_error_with_message(Calcpace::NonPositiveInputError, 'Stride') do
      @calc.cadence_for_stride('05:00', -1.2)
    end
  end

  def test_cadence_for_stride_rejects_non_positive_pace
    assert_error_with_message(Calcpace::NonPositiveInputError, 'Pace') do
      @calc.cadence_for_stride(-300, 1.18)
    end
  end

  def test_cadence_for_stride_rejects_an_invalid_pace_string
    assert_raises(Calcpace::NonPositiveInputError) { @calc.cadence_for_stride('abc', 1.18) }
  end

  def test_cadence_for_stride_rejects_an_unsupported_unit
    error = assert_raises(Calcpace::UnsupportedUnitError) { @calc.cadence_for_stride('05:00', 1.18, unit: :yard) }

    assert_includes error.message, 'yard'
  end
end
