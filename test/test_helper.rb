# frozen_string_literal: true

if ENV['MEASURE_COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    enable_coverage :branch
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'boatload'

require 'logger'
require 'minitest/autorun'
require 'mocha/minitest'
require 'shoulda-context'
