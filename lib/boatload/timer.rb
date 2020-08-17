# frozen_string_literal: true

module Boatload
  # A timer that will periodically tell the Worker to process items.
  class Timer
    def initialize(queue:, delivery_interval:, logger:)
      @logger = logger
      @queue = queue
      @delivery_interval = delivery_interval
    end

    def run
      Thread.stop if @delivery_interval.zero?
      @logger.info 'Starting Timer...'

      loop do
        sleep @delivery_interval
        @queue.push [:process, nil]
      end
    rescue StandardError => e
      @logger.error "Timer thread encountered an unexpected error:\n#{e.full_message}"
    end
  end
end
