# frozen_string_literal: true

require_relative '../test_helper'
require 'open3'
require 'rbconfig'

class TestVersion < CalcpaceTest
  LIB = File.expand_path('../../lib', __dir__)

  # In a fresh process, so nothing else the suite loaded can define it
  def test_require_calcpace_defines_the_version
    out, status = Open3.capture2e(RbConfig.ruby, '-I', LIB, '-e', "require 'calcpace'; print Calcpace::VERSION")

    assert_predicate status, :success?, out
    assert_match(/\A\d+\.\d+\.\d+\z/, out)
  end

  def test_version_matches_the_gem_version_file
    assert_equal File.read(File.join(LIB, 'calcpace/version.rb'))[/VERSION = '([^']+)'/, 1], Calcpace::VERSION
  end
end
