# frozen_string_literal: true

require 'yaml'

# Module for age-grading race performances with a versioned table
#
# Age grading allows fairer comparison across ages by applying an age factor
# to the raw performance time.
#
# Current scope:
# - Common road distances: 5K, 10K, half marathon, marathon
# - Sex: male/female
# - Age: 18+
# - Data file is versioned and replaceable (`lib/calcpace/data/wma_2023_road.yml`)
#
# Returned values include:
# - age grade percentage
# - age-graded time
# - open standard time for the selected distance/sex
# - performance category
# rubocop:disable Metrics/ModuleLength
module AgeGrading
  DATA_PATH = File.expand_path('data/wma_2023_road.yml', __dir__).freeze
  OPEN_STANDARDS_DATA_PATH = File.expand_path('data/wma_2023_open_standards.yml', __dir__).freeze
  WMA_DATA = YAML.safe_load_file(DATA_PATH, permitted_classes: [],
                                            aliases: false).freeze
  OPEN_STANDARDS_DATA = YAML.safe_load_file(OPEN_STANDARDS_DATA_PATH, permitted_classes: [],
                                                                      aliases: false).freeze
  TABLE_VERSION = OPEN_STANDARDS_DATA.fetch('meta').fetch('table_version').freeze

  AGE_GRADE_LABELS = OPEN_STANDARDS_DATA.fetch('age_grade_classifications').map do |entry|
    { min: entry.fetch('min').to_f, label: entry.fetch('label') }
  end.freeze

  DISTANCE_TO_METERS = {
    5.0 => '5000',
    10.0 => '10000',
    21.0975 => '21097',
    42.195 => '42195'
  }.freeze
  RACE_TO_METERS = {
    '5k' => '5000',
    '10k' => '10000',
    'half_marathon' => '21097',
    'marathon' => '42195'
  }.freeze

  SUPPORTED_DISTANCES_KM = DISTANCE_TO_METERS.keys.freeze

  # Returns a full age-grading report for a race performance
  #
  # @param distance_km [Numeric, String, Symbol] race distance in kilometres
  #   (5.0, 10.0, 21.0975, 42.195) or race key (:5k, :10k, :half_marathon, :marathon)
  # @param time [String, Numeric] performance time as HH:MM:SS / MM:SS, or total seconds
  # @param age [Integer] athlete age (must be >= 18)
  # @param sex [String, Symbol] male or female
  # @return [Hash] age-grading result details
  def age_grade(distance_km, time, age:, sex:)
    distance_m = normalize_distance(distance_km)
    seconds = parse_time_seconds(time)
    age_value = normalize_age(age)
    sex_value = normalize_sex(sex)

    check_positive(seconds, 'Time')

    factor = interpolated_factor(sex_value, age_value, distance_m)
    age_graded_time = round_up_hundredth(seconds * factor)
    open_standard = open_standard_seconds(sex_value, distance_m)
    grade_percent = (open_standard / age_graded_time) * 100.0
    rounded_percent = grade_percent.round(1)

    {
      age_grade_percent: rounded_percent,
      category: age_grade_label(rounded_percent),
      age_graded_time_seconds: age_graded_time,
      age_graded_time_clock: convert_to_clocktime(age_graded_time),
      open_standard_seconds: open_standard,
      open_standard_clock: convert_to_clocktime(open_standard),
      factor: factor.round(4),
      table_version: TABLE_VERSION
    }
  end

  # Returns only the age-grade percentage
  #
  # @param distance_km [Numeric] race distance in kilometres
  # @param time [String, Numeric] performance time
  # @param age [Integer] athlete age
  # @param sex [String, Symbol] male or female
  # @return [Float] age-grade percentage
  def age_grade_percent(distance_km, time, age:, sex:)
    age_grade(distance_km, time, age: age, sex: sex)[:age_grade_percent]
  end

  # Returns a descriptive label for an age-grade percentage
  #
  # @param percent [Numeric] age-grade percentage
  # @return [String] category label
  def age_grade_label(percent)
    percent_value = begin
      Float(percent)
    rescue ArgumentError, TypeError
      raise ArgumentError, 'Age-grade percent must be a numeric value greater than or equal to 0'
    end

    raise ArgumentError, 'Age-grade percent must be greater than or equal to 0' if percent_value.negative?

    AGE_GRADE_LABELS.find { |entry| percent_value >= entry[:min] }[:label]
  end

  private

  def normalize_distance(distance_km)
    if distance_km.is_a?(String) || distance_km.is_a?(Symbol)
      key = distance_km.to_s.strip.downcase
      return RACE_TO_METERS.fetch(key) if RACE_TO_METERS.key?(key)

      raise ArgumentError,
            "Unsupported race '#{distance_km}'. Supported: #{RACE_TO_METERS.keys.join(', ')}"
    end

    distance = distance_km.to_f
    check_positive(distance, 'Distance')

    match = SUPPORTED_DISTANCES_KM.find { |value| (distance - value).abs <= 0.001 }
    return DISTANCE_TO_METERS.fetch(match) if match

    raise ArgumentError,
          "Unsupported distance #{distance_km}km. Supported: #{SUPPORTED_DISTANCES_KM.join(', ')}"
  end

  def parse_time_seconds(time)
    return time.to_f if time.is_a?(Numeric)

    check_time(time.to_s)
    convert_to_seconds(time.to_s)
  end

  def normalize_age(age)
    age_value = Integer(age)
  rescue ArgumentError, TypeError
    raise ArgumentError, 'Age must be an integer greater than or equal to 18'
  else
    raise ArgumentError, 'Age must be at least 18' if age_value < 18

    age_value
  end

  def normalize_sex(sex)
    normalized = sex.to_s.strip.downcase.to_sym
    return normalized if %i[male female].include?(normalized)

    raise ArgumentError, "Sex must be 'male' or 'female'"
  end

  def interpolated_factor(sex, age, distance_m)
    table = factor_table(sex, distance_m)
    ages = table.keys.map(&:to_i).sort

    return table.fetch(ages.first).to_f if age <= ages.first
    return table.fetch(ages.last).to_f if age >= ages.last

    lower_age, upper_age = neighboring_ages(ages, age)
    return table.fetch(lower_age).to_f if lower_age == upper_age

    interpolated_value(table, lower_age, upper_age, age)
  end

  def factor_table(sex, distance_m)
    WMA_DATA.fetch(sex_key(sex)).fetch(distance_m)
  end

  def sex_key(sex)
    sex == :male ? 'M' : 'F'
  end

  def open_standard_seconds(sex, distance_m)
    OPEN_STANDARDS_DATA.fetch('open_standards_seconds').fetch(sex_key(sex)).fetch(distance_m).to_f
  end

  def round_up_hundredth(value)
    (value * 100.0).ceil / 100.0
  end

  def neighboring_ages(ages, age)
    lower_age = ages.select { |value| value <= age }.max
    upper_age = ages.select { |value| value >= age }.min
    [lower_age, upper_age]
  end

  def interpolated_value(table, lower_age, upper_age, age)
    lower_factor = table.fetch(lower_age).to_f
    upper_factor = table.fetch(upper_age).to_f
    ratio = (age - lower_age).to_f / (upper_age - lower_age)
    lower_factor + ((upper_factor - lower_factor) * ratio)
  end
end
# rubocop:enable Metrics/ModuleLength
