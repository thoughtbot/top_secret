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

      # Creates a BatchResult from multiple messages with consistent global labeling
      #
      # @param messages [Array<String>] Array of text messages to filter
      # @param custom_filters [Array] Additional custom filters to apply
      # @param filters [Hash] Optional filters to override defaults (only valid filter keys accepted)
      # @return [BatchResult] Contains global mapping and array of Result objects with individual mappings
      # @raise [ArgumentError] If invalid filter keys are provided
      def self.from_messages(messages, custom_filters: [], **filters)
        individual_results = TopSecret::Text::Result.from_messages(messages, custom_filters:, **filters)
        mapping = TopSecret::Text::GlobalMapping.from_results(individual_results)
        items = TopSecret::Text::Result.with_global_labels(individual_results, mapping)

        Text::BatchResult.new(mapping:, items:)
      end
    end
  end
end
