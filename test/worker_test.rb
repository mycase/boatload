# frozen_string_literal: true

require 'logger'
require 'test_helper'

module Boatload
  class Worker
    attr_reader :backlog
  end

  class WorkerTest < Minitest::Test
    context '#run' do
      setup do
        @queue = Queue.new
        @worker = Worker.new(queue: @queue) {}
      end
    end

    context '#process' do
      setup do
        @queue = Queue.new
      end

      should 'call the process block with the items in the backlog' do
        processed = []
        worker = Worker.new(queue: @queue) do |items|
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

      should 'clear the backlog after completing successfully' do
        worker = Worker.new(queue: @queue) {}

        assert worker.backlog.empty?

        @queue.push [:item, 1]
        worker_thread = Thread.new { worker.run }

        @queue.push [:shutdown, nil]
        worker_thread.join

        assert worker.backlog.empty?
      end

      should 'catch any errors raised in the process block' do
        worker = Worker.new(queue: @queue) do |_items|
          raise 'always fail'
        end

        @queue.push [:item, 1]
        @queue.push [:shutdown, nil]
        worker.run
      end
    end
  end
end
