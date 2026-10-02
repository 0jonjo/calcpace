# frozen_string_literal: true

require_relative '../test_helper'

# Calcpace is one class made of many modules. A method defined in two of them
# is silently overwritten by whichever comes first in the ancestors, so the
# composition itself is tested here.
class TestModuleComposition < CalcpaceTest
  CALCPACE_MODULES = (Calcpace.ancestors.take_while { |mod| mod != Object } - [Calcpace]).freeze

  def test_no_two_modules_define_the_same_method
    owners = Hash.new { |hash, name| hash[name] = [] }
    CALCPACE_MODULES.each do |mod|
      (mod.instance_methods(false) + mod.private_instance_methods(false)).each { |name| owners[name] << mod }
    end
    shared = owners.select { |_name, mods| mods.size > 1 }

    assert_empty shared, "Methods defined in more than one module: #{shared.inspect}"
  end

  # Vo2maxNorms declares what it needs (Checker), so it works on its own
  def test_vo2max_norms_works_included_alone
    norms = Class.new { include Vo2maxNorms }.new

    assert_in_delta 40.5, norms.vo2max_percentile(45, age: 25, sex: :male)
    assert_raises(ArgumentError) { norms.vo2max_percentile(45, age: 17, sex: :male) }
    assert_raises(ArgumentError) { norms.vo2max_percentile(45, age: 25, sex: :other) }
    assert_raises(Calcpace::NonPositiveInputError) { norms.vo2max_percentile(0, age: 25, sex: :male) }
  end

  def test_age_and_sex_rules_are_shared_by_age_grading_and_vo2max_norms
    assert_equal Checker, Calcpace.instance_method(:normalize_age).owner
    assert_equal Checker, Calcpace.instance_method(:normalize_sex).owner
  end
end
