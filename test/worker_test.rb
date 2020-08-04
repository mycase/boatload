# frozen_string_literal: true

require 'test_helper'

module Boatload
  class Worker
    attr_reader :backlog
  end

  class WorkerTest < Minitest::Test
    context '#run' do
      setup do
        @queue = Queue.new
        @logger = create_logger
        @worker = Worker.new(queue: @queue, logger: @logger) {}
      end

      should 'log an error if an unknown operation is received' do
        @logger.expects(:error).with(includes('Unknown operation: :fake_operation'))
        @queue.push [:fake_operation, 42]
        @worker.run
      end
    end

    context '#process' do
      setup do
        @queue = Queue.new
        @logger = create_logger
      end

      should 'call the process block with the items in the backlog' do
        processed = []
        worker = Worker.new(queue: @queue, logger: @logger) do |items|
          processed.concat(items.map { |item| item + 1 })
        end

        @queue.push [:item, 1]
        @queue.push [:item, 2]
        @queue.push [:item, 3]

        worker_thread = Thread.new { worker.run }

        @queue.push [:shutdown, nil]
        worker_thread.join

        assert_equal [2, 3, 4], processed
      end

      should 'be able to use the logger from within the process block' do
        @logger.expects(:warn).with('testing 123')
        worker = Worker.new(queue: @queue, logger: @logger) do |_items, logger|
          logger.warn('testing 123')
        end

        worker_thread = Thread.new { worker.run }

        @queue.push [:shutdown, nil]
        worker_thread.join
      end

      should 'clear the backlog after completing successfully' do
        worker = Worker.new(queue: @queue, logger: @logger) {}

        assert worker.backlog.empty?

        @queue.push [:item, 1]
        worker_thread = Thread.new { worker.run }

        @queue.push [:shutdown, nil]
        worker_thread.join

        assert worker.backlog.empty?
      end

      should 'catch any errors raised in the process block' do
        @logger.expects(:error).with(includes('always fail'))

        worker = Worker.new(queue: @queue, logger: @logger) { raise 'always fail' }

        @queue.push [:item, 1]
        @queue.push [:shutdown, nil]
        worker.run
      end
    end

    # Create a dummy logger so we don't pollute the test output
    def create_logger
      Logger.new(StringIO.new)
    end
  end
end
