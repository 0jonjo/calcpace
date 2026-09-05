# frozen_string_literal: true

require_relative '../test_helper'

# Tests for LapAnalyzer module — interval structure detected from watch laps
class TestLapAnalyzer < CalcpaceTest
  # Warm-up, 6 × (1 km hard / 400 m jog), cool-down — the documented session.
  # The cool-down runs at 5:30/km, which is more than 15% faster than the 6:30/km
  # jog beside it: on contrast alone it would pass as a seventh rep.
  def classic_session
    [{ distance: 2.0, elapsed: 720 }] +
      ([{ distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 156 }] * 6) +
      [{ distance: 1.5, elapsed: 495 }]
  end

  # --- the documented session ---
  def test_interval_structure_documented_example
    structure = @calc.interval_structure(classic_session)

    assert_equal 6, structure.reps
    assert_in_delta 1.0, structure.work_distance
    assert_equal 252, structure.work_pace
    assert_equal 390, structure.rest_pace
    assert_equal 156, structure.rest_duration
  end

  def test_interval_structure_returns_integer_paces_and_durations
    structure = @calc.interval_structure(classic_session)

    assert_kind_of Integer, structure.reps
    assert_kind_of Integer, structure.work_pace
    assert_kind_of Integer, structure.rest_pace
    assert_kind_of Integer, structure.rest_duration
    assert_kind_of Float, structure.work_distance
  end

  def test_interval_structure_ignores_warm_up_and_cool_down
    without_edges = classic_session[1..-2]

    assert_equal @calc.interval_structure(classic_session).reps,
                 @calc.interval_structure(without_edges).reps
  end

  # --- units ---
  def test_interval_structure_converts_both_paces_to_miles
    structure = @calc.interval_structure(classic_session, unit: :mi)

    assert_equal 406, structure.work_pace # 252 s/km × 1.609344
    assert_equal 628, structure.rest_pace # 390 s/km × 1.609344
  end

  def test_interval_structure_keeps_distance_in_kilometres_in_miles_mode
    structure = @calc.interval_structure(classic_session, unit: :mi)

    assert_in_delta 1.0, structure.work_distance
  end

  def test_interval_structure_leaves_reps_and_rest_duration_unchanged_by_unit
    km = @calc.interval_structure(classic_session)
    mi = @calc.interval_structure(classic_session, unit: :mi)

    assert_equal km.reps, mi.reps
    assert_equal km.rest_duration, mi.rest_duration
  end

  def test_interval_structure_accepts_the_unit_as_a_string
    assert_equal @calc.interval_structure(classic_session, unit: :mi).work_pace,
                 @calc.interval_structure(classic_session, unit: 'mi').work_pace
  end

  def test_interval_structure_rejects_an_unsupported_unit
    error = assert_raises(Calcpace::UnsupportedUnitError) do
      @calc.interval_structure(classic_session, unit: :furlong)
    end

    assert_includes error.message, 'furlong'
  end

  def test_interval_structure_checks_the_unit_before_the_laps
    assert_raises(Calcpace::UnsupportedUnitError) do
      @calc.interval_structure([{ distance: -1, elapsed: 0 }], unit: :furlong)
    end
  end

  # --- shapes a real watch produces ---
  def test_interval_structure_reads_a_standing_recovery_as_rest_without_a_pace
    laps = [{ distance: 2.0, elapsed: 720 },
            { distance: 1.0, elapsed: 252 }, { distance: 0.0, elapsed: 120 },
            { distance: 1.0, elapsed: 252 }, { distance: 0.0, elapsed: 120 },
            { distance: 1.0, elapsed: 252 },
            { distance: 1.5, elapsed: 540 }]
    structure = @calc.interval_structure(laps)

    assert_equal 3, structure.reps
    assert_nil structure.rest_pace # standing still covers no distance
    assert_equal 120, structure.rest_duration
  end

  def test_interval_structure_finds_a_work_lap_that_ends_the_session
    laps = [{ distance: 2.0, elapsed: 720 },
            { distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 156 },
            { distance: 1.0, elapsed: 252 }]
    structure = @calc.interval_structure(laps)

    assert_equal 2, structure.reps
    assert_equal 252, structure.work_pace
    assert_equal 390, structure.rest_pace
  end

  def test_interval_structure_finds_a_work_lap_that_opens_the_session
    laps = [{ distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 156 },
            { distance: 1.0, elapsed: 252 }, { distance: 1.5, elapsed: 540 }]
    structure = @calc.interval_structure(laps)

    assert_equal 2, structure.reps
    assert_in_delta 1.0, structure.work_distance
  end

  def test_interval_structure_averages_uneven_rest_laps
    laps = [{ distance: 2.0, elapsed: 720 },
            { distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 150 },
            { distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 162 },
            { distance: 1.0, elapsed: 252 },
            { distance: 1.5, elapsed: 540 }]
    structure = @calc.interval_structure(laps)

    assert_equal 3, structure.reps
    assert_equal 156, structure.rest_duration      # (150 + 162) / 2
    assert_equal 390, structure.rest_pace          # 312 s over 0.8 km
  end

  def test_interval_structure_weights_work_pace_by_distance
    laps = [{ distance: 2.0, elapsed: 720 },
            { distance: 1.2, elapsed: 288 }, { distance: 0.4, elapsed: 156 },
            { distance: 0.8, elapsed: 208 },
            { distance: 1.5, elapsed: 540 }]
    structure = @calc.interval_structure(laps)

    assert_equal 2, structure.reps
    assert_equal 248, structure.work_pace          # (288 + 208) / (1.2 + 0.8)
    assert_in_delta 1.0, structure.work_distance   # median of 1.2 and 0.8
  end

  # --- edge laps have to earn their place ---
  # A warm-up or a cool-down has only one neighbour, so contrast alone is a free
  # pass: it just has to beat the recovery it happens to touch. An edge lap only
  # counts as work when it also agrees with the reps found in the interior.
  def test_interval_structure_rejects_a_cool_down_that_only_beats_the_last_jog
    # 8 × 400 m at 3:20/km with 200 m jogs at 7:30/km, then 1 km at 6:00/km
    laps = ([{ distance: 0.4, elapsed: 80 }, { distance: 0.2, elapsed: 90 }] * 8) +
           [{ distance: 1.0, elapsed: 360 }]
    structure = @calc.interval_structure(laps)

    assert_equal 8, structure.reps
    assert_in_delta 0.4, structure.work_distance
    assert_equal 200, structure.work_pace
    assert_equal 450, structure.rest_pace
  end

  def test_interval_structure_rejects_a_cool_down_that_is_too_long_to_be_a_rep
    # 6 × 1 km at 4:12, 400 m jogs at 6:30, 1.5 km cool-down at 5:30
    laps = ([{ distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 156 }] * 6) +
           [{ distance: 1.5, elapsed: 495 }]

    assert_equal 6, @calc.interval_structure(laps).reps
  end

  # The cool-down is the right length here, so only the pace rules it out
  def test_interval_structure_rejects_a_cool_down_too_slow_to_be_a_rep
    # 5 × 1 km at 4:12 with 400 m jogs, then 1.2 km at 5:20
    laps = ([{ distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 156 }] * 5) +
           [{ distance: 1.2, elapsed: 384 }]

    assert_equal 5, @calc.interval_structure(laps).reps
  end

  def test_interval_structure_rejects_a_cool_down_after_a_standing_recovery
    # The last recovery covers no distance, so the cool-down's only neighbour is
    # an infinite pace and contrast alone would wave it through as a fifth rep.
    # The warm-up is what gives the reps a finite pace to beat (see the pauses
    # test below): without it the session carries no evidence at all.
    laps = [{ distance: 2.0, elapsed: 720 }] +
           ([{ distance: 1.0, elapsed: 252 }, { distance: 0.0, elapsed: 120 }] * 4) +
           [{ distance: 1.5, elapsed: 495 }]
    structure = @calc.interval_structure(laps)

    assert_equal 4, structure.reps
    assert_in_delta 1.0, structure.work_distance
  end

  # With no interior work lap to compare against there is nothing to agree with,
  # so the plain contrast rule still stands and the shortest session works
  def test_interval_structure_falls_back_to_contrast_when_the_interior_is_empty
    laps = [{ distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 156 },
            { distance: 1.0, elapsed: 252 }]

    assert_equal [2, 1.0, 252, 390, 156], @calc.interval_structure(laps).to_a
  end

  # --- sessions that have no structure ---
  # An infinitely fast neighbour is no evidence: every lap beside a pause looks
  # 15% faster than it. Something in the set has to have beaten a real pace.
  def test_interval_structure_returns_nil_for_an_easy_run_with_lap_pauses
    laps = [{ distance: 1.0, elapsed: 300 }, { distance: 0.0, elapsed: 45 },
            { distance: 1.0, elapsed: 300 }, { distance: 0.0, elapsed: 50 },
            { distance: 1.0, elapsed: 300 }]

    assert_nil @calc.interval_structure(laps)
  end

  def test_interval_structure_returns_nil_for_a_steady_run
    laps = [300, 298, 302, 296, 304, 300, 299, 301, 305, 295].map do |elapsed|
      { distance: 1.0, elapsed: elapsed }
    end

    assert_nil @calc.interval_structure(laps)
  end

  def test_interval_structure_returns_nil_for_a_single_hard_effort
    laps = [{ distance: 2.0, elapsed: 720 },
            { distance: 1.0, elapsed: 252 },
            { distance: 1.5, elapsed: 540 }]

    assert_nil @calc.interval_structure(laps)
  end

  def test_interval_structure_returns_nil_when_work_distances_disagree
    laps = [{ distance: 2.0, elapsed: 720 },
            { distance: 1.0, elapsed: 252 }, { distance: 0.4, elapsed: 156 },
            { distance: 2.0, elapsed: 504 }, { distance: 0.4, elapsed: 156 },
            { distance: 1.0, elapsed: 252 },
            { distance: 1.5, elapsed: 540 }]

    assert_nil @calc.interval_structure(laps)
  end

  def test_interval_structure_accepts_work_distances_inside_the_quarter_tolerance
    laps = [{ distance: 2.0, elapsed: 720 },
            { distance: 1.2, elapsed: 288 }, { distance: 0.4, elapsed: 156 },
            { distance: 0.8, elapsed: 192 }, { distance: 0.4, elapsed: 156 },
            { distance: 1.0, elapsed: 240 },
            { distance: 1.5, elapsed: 540 }]

    refute_nil @calc.interval_structure(laps)
  end

  def test_interval_structure_returns_nil_for_no_laps
    assert_nil @calc.interval_structure([])
  end

  def test_interval_structure_returns_nil_for_a_single_lap
    assert_nil @calc.interval_structure([{ distance: 10.0, elapsed: 3000 }])
  end

  def test_interval_structure_ignores_a_short_fast_lap_as_work
    # A 60 m lap split by hand is faster than its neighbours but too short to
    # be a rep — under the 0.1 km floor it can never count as work.
    laps = [{ distance: 2.0, elapsed: 720 }, { distance: 0.06, elapsed: 12 },
            { distance: 2.0, elapsed: 720 }, { distance: 0.06, elapsed: 12 },
            { distance: 2.0, elapsed: 720 }]

    assert_nil @calc.interval_structure(laps)
  end

  # --- malformed input ---
  def test_interval_structure_rejects_a_lap_without_a_distance
    assert_error_with_message(Calcpace::Error, 'distance') do
      @calc.interval_structure([{ elapsed: 252 }, { distance: 0.4, elapsed: 156 }])
    end
  end

  def test_interval_structure_rejects_a_lap_without_an_elapsed_time
    assert_error_with_message(Calcpace::Error, 'elapsed') do
      @calc.interval_structure([{ distance: 1.0 }, { distance: 0.4, elapsed: 156 }])
    end
  end

  def test_interval_structure_rejects_a_negative_distance
    assert_error_with_message(Calcpace::Error, 'distance') do
      @calc.interval_structure([{ distance: -1.0, elapsed: 252 }])
    end
  end

  def test_interval_structure_rejects_a_zero_elapsed_time
    assert_error_with_message(Calcpace::Error, 'elapsed') do
      @calc.interval_structure([{ distance: 1.0, elapsed: 0 }])
    end
  end

  def test_interval_structure_rejects_a_negative_elapsed_time
    assert_error_with_message(Calcpace::Error, 'elapsed') do
      @calc.interval_structure([{ distance: 1.0, elapsed: -60 }])
    end
  end

  # A lap of 1000 is a runner who passed metres. Nothing in a running session
  # is 100 km long, and reading it as kilometres would silently return paces
  # that are off by a factor of a thousand.
  def test_interval_structure_rejects_a_distance_that_looks_like_metres
    assert_error_with_message(Calcpace::Error, 'kilometres') do
      @calc.interval_structure([{ distance: 1000, elapsed: 252 }, { distance: 400, elapsed: 156 }])
    end
  end

  def test_interval_structure_accepts_a_distance_at_the_sanity_floor
    laps = [{ distance: 100, elapsed: 36_000 }, { distance: 1.0, elapsed: 252 }]

    assert_nil @calc.interval_structure(laps) # legal input, just not a workout
  end

  def test_interval_structure_rejects_a_lap_that_is_not_a_hash
    assert_raises(Calcpace::Error) { @calc.interval_structure([nil, { distance: 1.0, elapsed: 252 }]) }
  end

  def test_interval_structure_rejects_a_non_numeric_value
    assert_error_with_message(Calcpace::Error, 'elapsed') do
      @calc.interval_structure([{ distance: 1.0, elapsed: '04:12' }])
    end
  end

  def test_interval_structure_accepts_string_keys
    with_symbols = classic_session
    with_strings = with_symbols.map { |lap| { 'distance' => lap[:distance], 'elapsed' => lap[:elapsed] } }

    assert_equal @calc.interval_structure(with_symbols).to_a,
                 @calc.interval_structure(with_strings).to_a
  end

  def test_interval_structure_accepts_integer_distances
    laps = [{ distance: 2, elapsed: 720 },
            { distance: 1, elapsed: 252 }, { distance: 0, elapsed: 120 },
            { distance: 1, elapsed: 252 }]
    structure = @calc.interval_structure(laps)

    assert_equal 2, structure.reps
    assert_in_delta 1.0, structure.work_distance
  end
end
