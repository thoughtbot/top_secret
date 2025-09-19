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

      # Creates a BatchResult from multiple messages with consistent global labeling
      #
      # @param messages [Array<String>] Array of text messages to filter
      # @param custom_filters [Array] Additional custom filters to apply
      # @param filters [Hash] Optional filters to override defaults (only valid filter keys accepted)
      # @return [BatchResult] Contains global mapping and array of Item objects with individual mappings
      # @raise [ArgumentError] If invalid filter keys are provided
      def self.from_messages(messages, custom_filters: [], **filters)
        individual_results = TopSecret::Text::Result.from_messages(messages, custom_filters:, **filters)
        mapping = TopSecret::Text::GlobalMapping.from_results(individual_results)
        items = Text::BatchResult::Item.from_results(individual_results, mapping)

        Text::BatchResult.new(mapping:, items:)
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

        # Creates Item objects from individual results using global mapping for consistent labels
        #
        # @param individual_results [Array<Result>] Array of individual filter results
        # @param global_mapping [Hash] Global mapping from filter labels to original values
        # @return [Array<Item>] Array of Item objects with globally consistent redaction
        def self.from_results(individual_results, global_mapping)
          individual_results.map do |result|
            output = result.input.dup
            global_mapping.each { |filter, value| output.gsub!(value, "[#{filter}]") }
            Text::BatchResult::Item.new(result.input, output)
          end
        end
      end
    end
  end
end
