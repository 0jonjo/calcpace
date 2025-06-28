# frozen_string_literal: true

class Calcpace
  class Error < StandardError; end

  class InvalidTimeFormatError < Error; end

  class NonPositiveInputError < Error; end
end
