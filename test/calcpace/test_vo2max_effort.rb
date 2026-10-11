# frozen_string_literal: true

require_relative '../test_helper'

# The effort: keyword of estimate_detailed_vo2max — what the runner says the
# effort was. It never changes the value, only how far it can be trusted.
class TestVo2maxEffort < CalcpaceTest
  # One effort per confidence band of the duration rule
  EFFORTS = {
    short: [1.0, '00:04:00'],          # under 5 min
    optimal: [10.0, '00:40:00'],       # 5–60 min
    long: [21.0975, '01:40:00'],       # 60–120 min
    ultra: [42.195, '04:00:00']        # over 120 min
  }.freeze

  HEART_RATES = {
    none: {},
    sub_maximal: { hr_avg: 140, hr_max: 200 }, # 70 % HRmax
    maximal: { hr_avg: 180, hr_max: 200 }      # 90 % HRmax
  }.freeze

  # [value, confidence, sub_maximal, adjusted_distance_km] from 2.0.0, with
  # 50 m of gain, for every effort and heart rate above
  RESULTS_V2 = {
    %i[short none] => [58.7, :low, false, 1.3],
    %i[short sub_maximal] => [58.7, :low, true, 1.3],
    %i[short maximal] => [58.7, :low, false, 1.3],
    %i[optimal none] => [53.9, :high, false, 10.3],
    %i[optimal sub_maximal] => [53.9, :low, true, 10.3],
    %i[optimal maximal] => [53.9, :high, false, 10.3],
    %i[long none] => [45.9, :medium, false, 21.4],
    %i[long sub_maximal] => [45.9, :low, true, 21.4],
    %i[long maximal] => [45.9, :medium, false, 21.4],
    %i[ultra none] => [38.2, :low, false, 42.5],
    %i[ultra sub_maximal] => [38.2, :low, true, 42.5],
    %i[ultra maximal] => [38.2, :low, false, 42.5]
  }.freeze

  def detailed(effort_key, hr_key, effort: nil)
    distance, time = EFFORTS.fetch(effort_key)
    @calc.estimate_detailed_vo2max(distance, time, elevation_gain_m: 50, **HEART_RATES.fetch(hr_key), effort: effort)
  end

  def verdict(result)
    [result.confidence, result.sub_maximal, result.basis]
  end

  def each_case(&)
    EFFORTS.each_key { |effort_key| HEART_RATES.each_key { |hr_key| yield effort_key, hr_key } }
  end

  def test_effort_levels_are_ordered_from_easiest
    assert_equal %i[easy moderate hard max], Vo2maxEffort::EFFORT_LEVELS
    assert_predicate Vo2maxEffort::EFFORT_LEVELS, :frozen?
  end

  def test_without_effort_matches_version_two
    each_case do |effort_key, hr_key|
      result = detailed(effort_key, hr_key)

      assert_equal RESULTS_V2.fetch([effort_key, hr_key]), result.to_a.first(4), "#{effort_key}/#{hr_key}"
    end
  end

  def test_without_effort_the_basis_is_the_duration_unless_heart_rate_downgraded_it
    each_case do |effort_key, hr_key|
      expected = hr_key == :sub_maximal ? :heart_rate : :duration

      assert_equal expected, detailed(effort_key, hr_key).basis, "#{effort_key}/#{hr_key}"
    end
  end

  def test_effort_never_changes_the_value_or_the_adjusted_distance
    each_case do |effort_key, hr_key|
      baseline = RESULTS_V2.fetch([effort_key, hr_key])

      Vo2maxEffort::EFFORT_LEVELS.each do |effort|
        result = detailed(effort_key, hr_key, effort: effort)

        assert_equal [baseline[0], baseline[3]], [result.value, result.adjusted_distance_km],
                     "#{effort_key}/#{hr_key}/#{effort}"
      end
    end
  end

  def test_easy_and_moderate_are_sub_maximal_and_low_whatever_the_duration_and_heart_rate
    each_case do |effort_key, hr_key|
      %i[easy moderate].each do |effort|
        assert_equal [:low, true, :declared], verdict(detailed(effort_key, hr_key, effort: effort)),
                     "#{effort_key}/#{hr_key}/#{effort}"
      end
    end
  end

  def test_hard_follows_the_version_two_rules
    each_case do |effort_key, hr_key|
      result = detailed(effort_key, hr_key, effort: :hard)
      _, confidence, sub_maximal, = RESULTS_V2.fetch([effort_key, hr_key])
      basis = hr_key == :sub_maximal ? :heart_rate : :duration

      assert_equal [confidence, sub_maximal, basis], verdict(result), "#{effort_key}/#{hr_key}"
    end
  end

  def test_max_is_high_confidence_from_five_minutes_on_however_long_it_took
    %i[optimal long ultra].each do |effort_key|
      %i[none maximal].each do |hr_key|
        assert_equal [:high, false, :declared], verdict(detailed(effort_key, hr_key, effort: :max)),
                     "#{effort_key}/#{hr_key}"
      end
    end
  end

  # Daniels & Gilbert is not reliable under five minutes, where anaerobic
  # energy carries the effort — declaring it all-out does not change that
  def test_max_under_five_minutes_keeps_the_duration_rule
    %i[none maximal].each do |hr_key|
      assert_equal [:low, false, :duration], verdict(detailed(:short, hr_key, effort: :max)), hr_key.to_s
    end
  end

  def test_max_switches_to_declared_at_exactly_five_minutes
    just_under = @calc.estimate_detailed_vo2max(1.2, 299, effort: :max)
    at_five = @calc.estimate_detailed_vo2max(1.2, 300, effort: :max)

    assert_equal [:low, false, :duration], verdict(just_under)
    assert_equal [:high, false, :declared], verdict(at_five)
  end

  def test_effort_works_with_numeric_time_and_miles
    km = @calc.estimate_detailed_vo2max(42.195, 12_600, effort: :max)
    mi = @calc.estimate_detailed_vo2max(26.2188, 12_600, distance_unit: :mi, effort: :max)

    assert_equal [:high, false, :declared], verdict(km)
    assert_equal verdict(km), verdict(mi)
    assert_in_delta km.value, mi.value, 0.1
  end

  def test_heart_rate_still_overrules_a_declared_max
    EFFORTS.each_key do |effort_key|
      assert_equal [:low, true, :heart_rate], verdict(detailed(effort_key, :sub_maximal, effort: :max)),
                   effort_key.to_s
    end
  end

  def test_without_heart_rate_a_declared_max_or_hard_is_not_sub_maximal
    EFFORTS.each_key do |effort_key|
      %i[hard max].each do |effort|
        refute detailed(effort_key, :none, effort: effort).sub_maximal, "#{effort_key}/#{effort}"
      end
    end
  end

  def test_accepts_effort_as_a_string_in_any_case
    assert_equal verdict(detailed(:long, :none, effort: :max)), verdict(detailed(:long, :none, effort: 'max'))
    assert_equal verdict(detailed(:long, :none, effort: :easy)), verdict(detailed(:long, :none, effort: 'Easy'))
  end

  def test_rejects_an_unknown_effort
    ['race', :tempo, '', 3].each do |effort|
      error = assert_raises(Calcpace::InvalidEffortError, effort.inspect) do
        @calc.estimate_detailed_vo2max(10.0, '00:40:00', effort: effort)
      end
      assert_includes error.message, effort.inspect
      assert_includes error.message, ':easy, :moderate, :hard, :max'
    end
  end

  def test_rejects_an_unknown_effort_before_any_other_check
    [
      [[10.0, '00:40:00'], { hr_avg: 140 }],
      [[0, '00:40:00'], {}],
      [[10.0, 'abc'], {}],
      [[10.0, '00:40:00'], { distance_unit: :furlong }]
    ].each do |args, kwargs|
      assert_raises(Calcpace::InvalidEffortError, kwargs.inspect) do
        @calc.estimate_detailed_vo2max(*args, **kwargs, effort: :tempo)
      end
    end
  end

  def test_invalid_effort_error_is_a_calcpace_error
    assert_kind_of Calcpace::Error, Calcpace::InvalidEffortError.new
  end

  def test_basis_is_the_last_member_so_positional_construction_still_works
    assert_equal %i[value confidence sub_maximal adjusted_distance_km basis], Vo2maxEstimator::Vo2maxResult.members
  end
end
