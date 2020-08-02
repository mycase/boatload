# frozen_string_literal: true

module Boatload
  # A worker that will run in the background, batching up and processing messages.
  class Worker
    def initialize(queue:, &block)
      @backlog = []
      @incoming_queue = queue
      @process_proc = block
    end

    def run
      loop do
        operation, payload = @incoming_queue.pop

        case operation
        when :item
          @backlog.push payload
        when :process
          process
        when :shutdown
          process
          break
        else
          raise "Unknown operation: #{operation.inspect}"
        end
      end
    rescue StandardError => _e
      nil
    end

    private

    def process
      @process_proc.call @backlog
      @backlog.clear
    rescue StandardError => _e
      nil
    end
  end
end
