# frozen_string_literal: true

require 'test_helper'

module Boatload
  class TimerTest < Minitest::Test
    context '#run' do
      setup do
        @queue = Queue.new
        @logger = create_logger
        @interval = 0.02
        @timer = Timer.new(queue: @queue, logger: @logger, delivery_interval: @interval) {}
      end

      should 'log an error if an unknown error occurs' do
        @logger.stubs(:info).raises('self-destruct')
        @logger.expects(:error).with(includes('self-destruct'))
        @timer.run
      end

      should 'kick off a batch process after waiting for `interval` seconds' do
        @queue.expects(:push).with([:process, nil])
        timer_thread = Thread.new { @timer.run }
        sleep @interval + 0.01

        timer_thread.exit
      end
    end

    private

    # Create a dummy logger so we don't pollute the test output
    def create_logger
      Logger.new(StringIO.new)
    end
  end
end
