# frozen_string_literal: true

require 'boatload/timer'
require 'boatload/worker'
require 'logger'

module Boatload
  # A class for asynchronously enqueueing work to be processed in large batches.
  class AsyncBatchProcessor
    def initialize(
      delivery_interval: 0,
      max_backlog_size: 0,
      logger: Logger.new(STDOUT),
      context: nil,
      &block
    )
      raise ArgumentError, 'delivery_interval must not be negative' if delivery_interval.negative?
      raise ArgumentError, 'max_backlog_size must not be negative' if max_backlog_size.negative?
      raise ArgumentError, 'You must give a block' unless block_given?

      @queue = Queue.new
      @logger = logger

      @worker = Worker.new(
        queue: @queue,
        max_backlog_size: max_backlog_size,
        logger: @logger,
        context: context,
        &block
      )

      @timer = Timer.new(
        queue: @queue,
        delivery_interval: delivery_interval,
        logger: @logger
      )

      @thread_mutex = Mutex.new
      @worker_thread = @timer_thread = nil
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
      @timer_thread&.exit
      @timer_thread&.join
      @worker_thread&.join
      nil
    end

    private

    def ensure_threads_running!
      return if worker_thread_alive? && timer_thread_alive?

      @thread_mutex.synchronize do
        start_worker_thread!
        start_timer_thread!
      end
    end

    def worker_thread_alive?
      !!@worker_thread&.alive?
    end

    def timer_thread_alive?
      !!@timer_thread&.alive?
    end

    def start_timer_thread!
      return if timer_thread_alive?

      @timer_thread = Thread.new { @timer.run }
    end

    def start_worker_thread!
      return if worker_thread_alive?

      @worker_thread = Thread.new { @worker.run }
    end
  end
end
