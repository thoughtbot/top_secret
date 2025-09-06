# frozen_string_literal: true

module TopSecret
  class Text
    # Holds the result of a batch redaction operation on multiple messages.
    # Contains a global mapping that ensures consistent labeling across all messages
    # and a collection of individual input/output pairs.
    class BatchResult # TODO Rename to FilterBatchResult
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

      # Represents a single message within a batch redaction operation.
      # Contains only the input and output text, without individual mappings.
      # The mapping is maintained at the BatchResult level for global consistency.
      class Item
        # @return [String] The original unredacted input
        attr_reader :input

        # @return [String] The redacted output
        attr_reader :output

        # Creates a new Item instance
        #
        # @param input [String] The original text
        # @param output [String] The redacted text
        def initialize(input, output)
          @input = input
          @output = output
        end
      end
    end
  end
end
