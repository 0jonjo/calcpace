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

  raw_age_grade_labels = OPEN_STANDARDS_DATA.fetch('age_grade_classifications').map do |entry|
    { min: entry.fetch('min').to_f, label: entry.fetch('label') }
  end
  AGE_GRADE_LABELS = raw_age_grade_labels.sort_by { |entry| -entry[:min] }.freeze

  unless AGE_GRADE_LABELS.last && AGE_GRADE_LABELS.last[:min] == 0.0
    raise ArgumentError, 'age_grade_classifications must end with a min of 0.0'
  end

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

  # How far a distance may sit from a standard and still be graded as it. 2% is
  # the same window calcpace.app uses to decide a run "is a 5K", so the gem and
  # the site never disagree about the same run. It stays a matching tolerance,
  # not an interpolation: a distance outside it has no WMA factor and is refused
  STANDARD_DISTANCE_TOLERANCE_RATIO = 0.02

  # Floor for the window above, so a future shorter standard still matches
  MINIMUM_DISTANCE_TOLERANCE_KM = 0.001

  # Returns a full age-grading report for a race performance
  #
  # @param distance [Numeric, String, Symbol] race distance in kilometres
  #   (5.0, 10.0, 21.0975, 42.195) or race key (:5k, :10k, :half_marathon, :marathon);
  #   numeric input can also be given in miles via distance_unit: :mi
  # @param time [String, Numeric] performance time as HH:MM:SS / MM:SS, or total seconds
  # @param age [Integer] athlete age (must be >= 18)
  # @param sex [String, Symbol] male or female
  # @param distance_unit [Symbol] unit of a numeric distance input — :km (default) or :mi.
  #   Rejected when distance is a race key: standard races already carry their own
  #   distance, so the combination is always a caller mistake
  # @return [Hash] age-grading result details
  # @raise [ArgumentError] if the distance, race key, age or sex is not supported,
  #   or if distance_unit is combined with a race key
  # @raise [Calcpace::UnsupportedUnitError] if distance_unit is not :km or :mi
  # @raise [Calcpace::InvalidTimeFormatError] if time string is malformed
  def age_grade(distance, time, age:, sex:, distance_unit: nil)
    distance_m = normalize_distance(distance, distance_unit)
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
  # @param distance [Numeric, String, Symbol] race distance in kilometres or race key
  # @param time [String, Numeric] performance time
  # @param age [Integer] athlete age
  # @param sex [String, Symbol] male or female
  # @param distance_unit [Symbol] unit of a numeric distance input — :km (default) or :mi
  #   (rejected alongside race keys, see #age_grade)
  # @return [Float] age-grade percentage
  def age_grade_percent(distance, time, age:, sex:, distance_unit: nil)
    age_grade(distance, time, age: age, sex: sex, distance_unit: distance_unit)[:age_grade_percent]
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

    raise ArgumentError, 'Age-grade percent must be a finite number' unless percent_value.finite?
    raise ArgumentError, 'Age-grade percent must be greater than or equal to 0' if percent_value.negative?

    AGE_GRADE_LABELS.find { |entry| percent_value >= entry[:min] }[:label]
  end

  private

  def normalize_distance(distance_input, distance_unit = nil)
    if distance_input.is_a?(String) || distance_input.is_a?(Symbol)
      reject_distance_unit_with_race_name!(distance_unit, distance_input)
      return race_key_to_meters(distance_input)
    end

    distance = normalize_distance_km(distance_input, distance_unit || :km)
    check_positive(distance, 'Distance')

    match = SUPPORTED_DISTANCES_KM.find { |value| standard_distance?(distance, value) }
    return DISTANCE_TO_METERS.fetch(match) if match

    raise ArgumentError,
          "Unsupported distance #{distance_input}#{(distance_unit || :km).to_s.downcase}. " \
          "Supported: #{SUPPORTED_DISTANCES_KM.join(', ')} km"
  end

  def race_key_to_meters(race_input)
    # normalize_race_key is PaceCalculator's — one lookup convention gem-wide
    RACE_TO_METERS.fetch(normalize_race_key(race_input)) do
      raise ArgumentError,
            "Unknown race: #{race_input}. Available races: #{RACE_TO_METERS.keys.join(', ')}"
    end
  end

  # Runners write rounded distances (3.1 mi, 13.1 mi, 26.2 mi) and GPS watches
  # rarely read a 5K as exactly 5.000 km, so the match window is relative
  def standard_distance?(distance, standard)
    (distance - standard).abs <= [MINIMUM_DISTANCE_TOLERANCE_KM,
                                  standard * STANDARD_DISTANCE_TOLERANCE_RATIO].max
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
