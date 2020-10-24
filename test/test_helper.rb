# frozen_string_literal: true

if ENV['MEASURE_COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    enable_coverage :branch
    # TODO: minimum_coverage line: 100, branch: 100
    minimum_coverage line: 99, branch: 91
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'boatload'

require 'logger'
require 'minitest/autorun'
require 'minitest/reporters'
require 'mocha/minitest'
require 'shoulda-context'

Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new
