# frozen_string_literal: true

module Boatload
  # A worker that will run in the background, batching up and processing messages.
  class Worker
    def initialize(queue:, logger:, &block)
      @backlog = []
      @incoming_queue = queue
      @logger = logger
      @process_proc = block
    end

    def run
      @logger.info 'Starting Worker in the background...'

      loop do
        operation, payload = @incoming_queue.pop

        case operation
        when :item
          @backlog.push payload
        when :process
          process
        when :shutdown
          begin
            process
          rescue StandardError => e
            @logger.error "Failed to process backlog during shutdown: #{e.message}"
          end

          break
        else
          raise "Unknown operation: #{operation.inspect}"
        end
      end
    rescue StandardError => e
      @logger.error "Worker thread encountered an unexpected error:\n#{e.full_message}"
    end

    private

    def process
      @process_proc.call @backlog
      @backlog.clear
    rescue StandardError => e
      @logger.error "Error encountered while processing backlog:\n#{e.full_message}"
    end
  end
end
