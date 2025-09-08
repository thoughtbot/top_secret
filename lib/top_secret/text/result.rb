# frozen_string_literal: true

module TopSecret
  class Text
    # Holds the result of a redaction operation.
    class Result # TODO: Rename to FilterResult
      include Mapping

      # @return [String] The original unredacted input
      attr_reader :input

      # @return [String] The redacted output
      attr_reader :output

      # @return [Hash] Mapping of redacted labels to matched values
      attr_reader :mapping

      # @param input [String] The original text
      # @param output [String] The redacted text
      # @param mapping [Hash] Map of labels to matched values
      def initialize(input, output, mapping)
        @input = input
        @output = output
        @mapping = mapping
      end

      # Filters multiple messages individually using a shared model for performance
      #
      # @param messages [Array<String>] Array of text messages to filter
      # @param custom_filters [Array] Additional custom filters to apply
      # @param filters [Hash] Optional filters to override defaults (only valid filter keys accepted)
      # @return [Array<Result>] Array of individual Result objects for each message
      # @raise [ArgumentError] If invalid filter keys are provided
      def self.from_messages(messages, custom_filters: [], **filters)
        shared_model = TopSecret.model_path ? Mitie::NER.new(TopSecret.model_path) : nil

        messages.map do |message|
          TopSecret::Text.new(message, filters:, custom_filters:, model: shared_model).filter
        end
      end

      # Creates Result objects with globally consistent labels applied to text
      #
      # @param individual_results [Array<Result>] Array of individual filter results
      # @param global_mapping [Hash] Global mapping from filter labels to original values
      # @return [Array<Result>] Array of Result objects with globally consistent redaction and individual mappings
      def self.with_global_labels(individual_results, global_mapping)
        individual_results.map do |result|
          output = global_mapping.reduce(result.input.dup) do |text, (filter, value)|
            text.gsub(value, "[#{filter}]")
          end
          filter_keys = output.scan(/\[([^\]]+)\]/).flatten.map(&:to_sym)
          mapping = global_mapping.slice(*filter_keys)
          new(result.input, output, mapping)
        end
      end
    end
  end
end
