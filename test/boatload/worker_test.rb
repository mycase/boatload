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

        [1, 2, 3].each { |i| @queue.push([:item, i]) }
        @queue.push [:shutdown, nil]
        worker.run

        assert_equal [2, 3, 4], processed
      end

      should 'be able to use the logger from within the process block' do
        @logger.expects(:warn).with('testing 123')
        worker = Worker.new(queue: @queue, logger: @logger) do |_items, logger|
          logger.warn('testing 123')
        end

        @queue.push [:shutdown, nil]
        worker.run
      end

      should 'call the process block with a user defined context' do
        processed = []
        context = { batches_processed: 0 }

        worker = Worker.new(
          queue: @queue,
          logger: @logger,
          context: context
        ) do |items, _logger, ctx|
          ctx[:batches_processed] += 1
          processed.concat(items.map { |item| item + 1 })
        end

        [1, 2, 3].each { |i| @queue.push([:item, i]) }
        @queue.push [:process, nil]
        [4, 5, 6].each { |i| @queue.push([:item, i]) }
        @queue.push [:shutdown, nil]
        worker.run

        assert_equal [2, 3, 4, 5, 6, 7], processed
        assert_equal 2, context[:batches_processed]
      end

      should 'clear the backlog after completing successfully' do
        worker = Worker.new(queue: @queue, logger: @logger) {}

        assert_empty worker.backlog

        @queue.push [:item, 1]
        @queue.push [:shutdown, nil]
        worker.run

        assert_empty worker.backlog
      end

      should 'not clear the backlog if an error is raised in the process block' do
        dummy = mock
        dummy.expects(:call).with([1]).raises
        dummy.expects(:call).with([1, 2])

        worker = Worker.new(queue: @queue, logger: @logger) do |items|
          dummy.call(items)
        end

        @queue.push [:item, 1]
        @queue.push [:process, nil]
        @queue.push [:item, 2]
        @queue.push [:shutdown, nil]
        worker.run
      end

      should 'catch any errors raised in the process block' do
        @logger.expects(:error).with(includes('always fail'))

        worker = Worker.new(queue: @queue, logger: @logger) { raise 'always fail' }

        @queue.push [:shutdown, nil]
        worker.run
      end
    end

    private

    # Create a dummy logger so we don't pollute the test output
    def create_logger
      Logger.new(StringIO.new)
    end
  end
end
