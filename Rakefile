# frozen_string_literal: true

require 'minitest/test_task'
require 'bundler/gem_tasks'

Minitest::TestTask.create(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.warning = false
end

task default: :test
