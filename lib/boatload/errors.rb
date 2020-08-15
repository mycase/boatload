# frozen_string_literal: true

module Boatload
  # Raised when the queue between an AsyncBatchProcessor and its Worker reaches its maximum size.
  class QueueOverflow < StandardError; end
end
