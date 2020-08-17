# frozen_string_literal: true

require 'boatload/timer'
require 'boatload/worker'
require 'logger'

module Boatload
  # A class for asynchronously enqueueing work to be processed in large batches.
  class AsyncBatchProcessor
    # Initializes a new AsyncBatchProcessor.
    #
    # @param delivery_interval [Integer] if greater than zero, the number of seconds between
    #   automatic batch processes.
    # @param max_backlog_size [Integer] if greater than zero, the number of backlog items that will
    #   automatically trigger a batch process.
    # @param max_queue_size [Integer] the maximum number of messages in the Queue before a
    #   QueueOverflow will be raised.
    # @param logger [Logger] a Logger that will be passed to the process Proc.
    # @param context [Object] additional context that will be passed to the process Proc.
    # @param &block [Proc] the code that processes items in the backlog.
    #
    # @yield [items, logger, context] Passes the backlog, a logger, and some context to the process
    #   Proc.
    def initialize(
      delivery_interval: 0,
      max_backlog_size: 0,
      max_queue_size: 1000,
      logger: Logger.new(STDOUT),
      context: nil,
      &block
    )
      raise ArgumentError, 'delivery_interval must not be negative' if delivery_interval.negative?
      raise ArgumentError, 'max_backlog_size must not be negative' if max_backlog_size.negative?
      raise ArgumentError, 'max_queue_size must be positive' unless max_queue_size.positive?
      raise ArgumentError, 'You must give a block' unless block_given?

      @queue = Queue.new
      @logger = logger
      @max_queue_size = max_queue_size

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

    # Adds an item to the backlog.
    #
    # @param items [*Object] the item to add to the backlog.
    # @raise [QueueOverflow] if the queue is full.
    # @return [nil]
    def push(*items)
      ensure_threads_running!

      items.each do |item|
        if @queue.size >= @max_queue_size
          raise QueueOverflow, "Max queue size (#{@max_queue_size} messages) reached"
        end

        @queue.push([:item, item])
      end

      nil
    end

    # Asynchronously processes the items in the backlog. This method will
    # return immediately and the actual work will be done in the background.
    #
    # @return [nil]
    def process
      ensure_threads_running!

      @queue.push [:process, nil]
      nil
    end

    # Processes any items in the backlog, shuts down the background worker, and
    # stops the timer. This method will block until the items in the backlog
    # have been processed.
    #
    # @return [nil]
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
