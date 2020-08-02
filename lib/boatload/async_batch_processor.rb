# frozen_string_literal: true

require 'boatload/worker'
require 'logger'

module Boatload
  # A class for asynchronously enqueueing work to be processed in large batches.
  class AsyncBatchProcessor
    def initialize(max_backlog_size: 0, logger: Logger.new(STDOUT), &block)
      raise ArgumentError, 'max_backlog_size must not be negative' if max_backlog_size.negative?
      raise ArgumentError, 'You must give a block' unless block_given?

      @queue = Queue.new
      @logger = logger

      @worker = Worker.new(
        queue: @queue,
        max_backlog_size: max_backlog_size,
        logger: @logger,
        &block
      )

      @thread_mutex = Mutex.new
      @worker_thread = nil
    end

    def push(*items)
      ensure_threads_running!

      items.each { |item| @queue.push([:item, item]) }
      nil
    end

    def process
      ensure_threads_running!

      @queue.push [:process, nil]
      nil
    end

    def shutdown
      ensure_threads_running!

      @queue.push [:shutdown, nil]
      @worker_thread&.join
      nil
    end

    private

    def ensure_threads_running!
      return if worker_thread_alive?

      @thread_mutex.synchronize do
        start_worker_thread!
      end
    end

    def worker_thread_alive?
      !!@worker_thread&.alive?
    end

    def start_worker_thread!
      return if worker_thread_alive?

      @worker_thread = Thread.new { @worker.run }
    end
  end
end
