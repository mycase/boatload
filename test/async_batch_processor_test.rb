# frozen_string_literal: true

require 'test_helper'

module Boatload
  # This method is private but it's useful in these tests
  AsyncBatchProcessor.send :public, :worker_thread_alive?

  class AsyncBatchProcessorTest < Minitest::Test
    context '#initialize' do
      should 'raise if no block is given' do
        assert_raises ArgumentError do
          AsyncBatchProcessor.new
        end
      end

      should 'not start worker thread' do
        abp = AsyncBatchProcessor.new {}

        refute abp.worker_thread_alive?
      end
    end

    context '#push' do
      setup do
        @processed = []
        @abp = AsyncBatchProcessor.new do |items|
          @processed.concat(items.map { |item| item + 1 })
        end
      end

      should 'allow pushing a variadic number of items' do
        Queue.any_instance.expects(:push).once
        @abp.push(1)

        Queue.any_instance.expects(:push).times(3)
        @abp.push(1, 2, 3)
      end

      should 'start worker thread if it is not alive' do
        refute @abp.worker_thread_alive?

        @abp.push(1)

        assert @abp.worker_thread_alive?
      end
    end

    context '#process' do
      setup do
        @queue = Queue.new
        @abp = AsyncBatchProcessor.new do |items|
          items.each { |item| @queue << item + 1 }
        end
      end

      should 'asynchronously process all items' do
        @abp.push(1, 2, 3)
        @abp.process

        processed = []
        3.times { processed << @queue.pop }

        assert_equal [2, 3, 4], processed
      end

      should 'start worker thread if it is not alive' do
        refute @abp.worker_thread_alive?

        @abp.process

        assert @abp.worker_thread_alive?
      end
    end

    context '#shutdown' do
      setup do
        @processed = []
        @abp = AsyncBatchProcessor.new do |items|
          @processed.concat(items.map { |item| item + 1 })
        end
      end

      should 'synchronously process all items' do
        @abp.push(1, 2, 3)
        @abp.shutdown

        assert_equal [2, 3, 4], @processed
      end

      should 'wait for the worker thread to exit' do
        @abp.shutdown

        refute @abp.worker_thread_alive?
      end

      should 'start worker thread if it is not alive' do
        refute @abp.worker_thread_alive?

        @abp.expects(:ensure_threads_running!)
        @abp.shutdown
      end
    end
  end
end
