# frozen_string_literal: true

require_relative '../test_helper'

# Runs the examples in the README and in the YARD docstrings and compares them
# with what the library actually returns.
#
# This exists because discipline failed twice. v1.14.0 shipped after its README
# examples were found to be invented; v1.15.0 was reviewed and three more wrong
# ones were still there, one of them contradicting a docstring the same release
# had just corrected. A published gem cannot be unpublished, and an example is
# the first thing a reader trusts.
#
# Only single-line examples of the form `calc.foo(...) # => value` are checked:
# they are unambiguous to parse and are the overwhelming majority. A multi-line
# hash example is left to the reader — the parser guessing at those is how a
# test starts lying about its own coverage.
class TestDocumentedExamples < CalcpaceTest
  ROOT = File.expand_path('../..', __dir__)

  # `calc.race_time(300, '5k') # => 1500` and its `#=>` docstring cousin.
  EXAMPLE = /^\s*#?\s*(?:calc|calculator)\.([a-z_0-9?]+\(.*?\))\s*#\s*=>\s*(.+?)\s*$/

  # Values a comment can carry that are not a Ruby literal to compare against.
  UNCOMPARABLE = /\A(?:\{|\[?#|.*\.\.\.)/

  def test_every_single_line_example_matches_what_the_code_returns
    mismatches = documented_examples.filter_map do |file, line_no, call, documented|
      actual = evaluate(call)
      next if actual == :uncomparable

      expected = parse_expected(documented)
      next if expected == :uncomparable
      next if values_match?(expected, actual)

      "#{file}:#{line_no}\n    #{call}\n    documented: #{documented}\n    actual:     #{actual.inspect}"
    end

    assert_empty mismatches, "Documented examples that do not match the code:\n\n#{mismatches.join("\n\n")}"
  end

  # A parser that silently matches nothing would pass this file forever, and so
  # would one that finds examples and then skips every one of them. Both numbers
  # are pinned: how many were found, and how many were actually compared.
  def test_the_scanner_finds_and_compares_a_known_number_of_examples
    assert_operator documented_examples.size, :>=, 60,
                    'the example scanner stopped finding examples — check EXAMPLE before trusting a green run'

    compared = documented_examples.count do |_file, _line, call, documented|
      evaluate(call) != :uncomparable && parse_expected(documented) != :uncomparable
    end

    # 49 at the time of writing. The gap is deliberate: multi-line hash results
    # and examples that document a raise are not comparable this way.
    assert_operator compared, :>=, 45,
                    "only #{compared} of #{documented_examples.size} examples were compared — " \
                    'this file is passing without checking what it claims to check'
  end

  private

  def documented_examples
    @documented_examples ||= documented_files.flat_map do |path|
      relative = path.delete_prefix("#{ROOT}/")

      File.readlines(path).each_with_index.filter_map do |line, index|
        match = EXAMPLE.match(line)
        next unless match

        [relative, index + 1, match[1], match[2]]
      end
    end
  end

  def documented_files
    [File.join(ROOT, 'README.md')] + Dir[File.join(ROOT, 'lib/calcpace/**/*.rb')]
  end

  # The documented call, sent to a real Calcpace instance. What gets evaluated
  # is a method call scraped from our own README and docstrings — never user
  # input — so `race_time(300, '5k')` becomes `self.race_time(300, '5k')`.
  def evaluate(call)
    @calc.instance_eval("self.#{call}", __FILE__, __LINE__)
  rescue StandardError, SyntaxError
    # An example that documents a raise, or one whose arguments are illustrative
    # rather than runnable, is not this test's business.
    :uncomparable
  end

  def parse_expected(documented)
    return :uncomparable if documented.match?(UNCOMPARABLE)

    Kernel.eval(documented, TOPLEVEL_BINDING, __FILE__, __LINE__) # rubocop:disable Security/Eval
  rescue StandardError, SyntaxError
    :uncomparable
  end

  # Floats in documentation are written to the precision a human would read, so
  # a documented 241.73 stands for the 241.73455… the code returns. Anything
  # further apart than the last documented digit is a real drift.
  def values_match?(expected, actual)
    return expected == actual unless expected.is_a?(Float) && actual.is_a?(Numeric)

    (expected - actual).abs <= (10**-decimals(expected)) / 2.0
  end

  def decimals(value)
    fraction = value.to_s.split('.').last
    fraction ? fraction.length : 0
  end
end
