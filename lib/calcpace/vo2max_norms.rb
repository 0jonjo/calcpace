# frozen_string_literal: true

require 'yaml'
require_relative 'errors'
require_relative 'checker'

# Module for reading a VO2max against people of the same age and sex
#
# Uses the FRIEND registry (Fitness Registry and the Importance of Exercise
# National Database) percentiles of VO2max measured by cardiopulmonary
# exercise testing in 7,783 treadmill tests on US adults free of known
# cardiovascular disease:
#
#   Kaminsky, L. A., Arena, R., & Myers, J. (2015). Reference Standards for
#   Cardiorespiratory Fitness Measured With Cardiopulmonary Exercise Testing:
#   Data From the Fitness Registry and the Importance of Exercise National
#   Database. Mayo Clinic Proceedings, 90(11), 1515–1523, Table 3.
#   https://doi.org/10.1016/j.mayocp.2015.07.026
#
# The table is stored, with its provenance, in
# `lib/calcpace/data/friend_2015_vo2max_percentiles.yml`.
# Vo2maxEstimator#vo2max_label uses it when given age and sex.
module Vo2maxNorms
  # check_positive, normalize_age and normalize_sex: the same rules as AgeGrading
  include Checker

  # Percentile norms by age and sex: FRIEND registry, measured treadmill VO2max
  # (Kaminsky, Arena & Myers, Mayo Clin Proc 2015;90(11):1515–1523, Table 3).
  # See the data file for the full provenance.
  NORMS_DATA_PATH = File.expand_path('data/friend_2015_vo2max_percentiles.yml', __dir__).freeze
  norms_data = YAML.safe_load_file(NORMS_DATA_PATH, permitted_classes: [], aliases: false)
  VO2MAX_NORMS_VERSION = norms_data.fetch('meta').fetch('table_version').freeze
  VO2MAX_NORM_PERCENTILES = norms_data.fetch('percentiles').map(&:to_f).freeze
  VO2MAX_NORMS = %w[M F].to_h do |sex|
    bands = norms_data.fetch(sex).to_h { |age, row| [Integer(age), row.map(&:to_f).freeze] }
    [sex.freeze, bands.freeze]
  end.freeze

  VO2MAX_NORMS.each do |sex, bands|
    bands.each do |age, row|
      next if row.size == VO2MAX_NORM_PERCENTILES.size && row.each_cons(2).all? { |low, high| high > low }

      raise Calcpace::InvalidDataError,
            "VO2max norms #{sex} #{age}: expected #{VO2MAX_NORM_PERCENTILES.size} rising values, got #{row.inspect}"
    end
  end

  # Percentile cut for each label when vo2max_label is given age and sex. The
  # cuts sit on percentiles the table publishes, so a label never depends on
  # interpolation: at or above the 95th percentile is Elite, the 90th
  # Excellent, the 75th Very Good, the median Good, the 25th Fair, and below
  # the 25th Beginner. These cuts are calcpace's choice — FRIEND publishes
  # percentiles, not labels.
  VO2MAX_PERCENTILE_LABELS = [
    { min: 95, label: 'Elite' },
    { min: 90, label: 'Excellent' },
    { min: 75, label: 'Very Good' },
    { min: 50, label: 'Good' },
    { min: 25, label: 'Fair' },
    { min: 0,  label: 'Beginner' }
  ].freeze

  # Approximate percentile of a VO2max among people of the same sex and age
  #
  # Reads the FRIEND registry percentiles (Kaminsky, Arena & Myers, 2015,
  # Table 3: 5th, 10th, 25th, 50th, 75th, 90th and 95th, by decade from 20–29 to
  # 70–79) and interpolates linearly between the two published percentiles
  # around the value. The registry measured VO2max in a lab; an estimate from a
  # race time carries its own ±3–5 ml/kg/min on top.
  #
  # - Age decades are used as published, without blending across them, so a
  #   29- and a 30-year-old read different rows. Ages 18–19 use the 20–29 row and
  #   80 or over the 70–79 row; under 18 is rejected (adult norms do not apply).
  # - The result is bounded to the table: 5.0 means at or below the 5th
  #   percentile, 95.0 at or above the 95th.
  #
  # @param value [Numeric] VO2max in ml/kg/min
  # @param age [Integer] age in years (18 or over; a fractional age is
  #   truncated, as in AgeGrading)
  # @param sex [String, Symbol] male or female
  # @return [Float] percentile between 5.0 and 95.0, rounded to one decimal
  # @raise [Calcpace::NonPositiveInputError] if value is not positive
  # @raise [ArgumentError] if age is under 18 or not a number, or sex is not male/female
  #
  # @example
  #   calc.vo2max_percentile(48.0, age: 25, sex: :male)  #=> 50.0
  #   calc.vo2max_percentile(45, age: 25, sex: :male)    #=> 40.5
  #   calc.vo2max_percentile(45, age: 25, sex: :female)  #=> 75.7
  #   calc.vo2max_percentile(45, age: 60, sex: :male)    #=> 95.0
  def vo2max_percentile(value, age:, sex:)
    check_positive(value.to_f, 'VO2max value')

    raw_vo2max_percentile(value.to_f, age, sex).round(1)
  end

  private

  # Unrounded percentile, so a label is decided against the published values
  # themselves rather than a rounded reading of them. normalize_age and
  # normalize_sex come from Checker — one rule for age and sex gem-wide.
  def raw_vo2max_percentile(value, age, sex)
    row = vo2max_norm_row(normalize_age(age), normalize_sex(sex))
    return VO2MAX_NORM_PERCENTILES.first if value <= row.first
    return VO2MAX_NORM_PERCENTILES.last if value >= row.last

    upper = row.index { |norm| norm > value }
    interpolate_percentile(row, upper, value)
  end

  def vo2max_norm_row(age, sex)
    bands = VO2MAX_NORMS.fetch(sex == :male ? 'M' : 'F')
    band = bands.keys.select { |lower| lower <= age }.max || bands.keys.min
    bands.fetch(band)
  end

  def interpolate_percentile(row, upper, value)
    low_norm, high_norm = row.values_at(upper - 1, upper)
    low_pct, high_pct = VO2MAX_NORM_PERCENTILES.values_at(upper - 1, upper)
    low_pct + ((high_pct - low_pct) * (value - low_norm) / (high_norm - low_norm))
  end
end
