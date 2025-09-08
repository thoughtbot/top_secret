# frozen_string_literal: true

module TopSecret
  class Text
    # Holds the result of a batch redaction operation on multiple messages.
    # Contains a global mapping that ensures consistent labeling across all messages
    # and a collection of individual input/output pairs.
    class BatchResult # TODO Rename to FilterBatchResult
      include Mapping

      # @return [Hash] Global mapping of redaction labels to original values across all messages
      attr_reader :mapping

      # @return [Array<Item>] Array of input/output pairs for each processed message
      attr_reader :items

      # Creates a new BatchResult instance
      #
      # @param mapping [Hash] Global mapping of redaction labels to original values
      # @param items [Array<Item>] Array of input/output pairs
      def initialize(mapping: {}, items: [])
        @mapping = mapping
        @items = items
      end
    end
  end
end
