# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'boatload'

require 'logger'
require 'minitest/autorun'
require 'minitest/reporters'
require 'mocha/minitest'
require 'shoulda-context'

require 'minitest/ci' if ENV['CI']

Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new
