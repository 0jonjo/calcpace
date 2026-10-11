# frozen_string_literal: true

# How hard the runner says an effort was, for Vo2maxEstimator#estimate_detailed_vo2max
#
# Daniels & Gilbert assume an all-out effort, and the estimator can only guess
# that from duration and heart rate. A declared effort answers it directly. It
# never changes the VO2max value — only its confidence, sub_maximal and basis.
module Vo2maxEffort
  # From easiest. :easy and :moderate are training (talk test: a full
  # conversation / short sentences), :hard is a few words at a time, :max is
  # everything the runner had — a race or a test.
  EFFORT_LEVELS = %i[easy moderate hard max].freeze

  private

  def normalize_effort(effort)
    return if effort.nil?

    level = effort.to_s.downcase.to_sym
    return level if EFFORT_LEVELS.include?(level)

    raise Calcpace::InvalidEffortError,
          "Invalid effort: #{effort.inspect}. Valid efforts: #{EFFORT_LEVELS.map(&:inspect).join(', ')}"
  end

  # A declared easy or moderate effort wins over everything: the runner knows
  # they held back, whatever the watch says. Heart rate wins over a declared
  # max, as it did over the duration rule. A max shorter than five minutes stays
  # with the duration rule: there the formula itself is unreliable.
  #
  # duration_confidence is the estimator's verdict from duration alone.
  def effort_verdict(effort, time_min, duration_confidence:, hr_sub_maximal:)
    if %i[easy moderate].include?(effort)
      { confidence: :low, sub_maximal: true, basis: :declared }
    elsif hr_sub_maximal
      { confidence: :low, sub_maximal: true, basis: :heart_rate }
    elsif effort == :max && time_min >= 5
      { confidence: :high, sub_maximal: false, basis: :declared }
    else
      { confidence: duration_confidence, sub_maximal: false, basis: :duration }
    end
  end
end
