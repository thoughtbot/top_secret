# frozen_string_literal: true

module TopSecret
  class Text
    # Manages consistent labeling across multiple filtering operations by ensuring
    # identical sensitive values receive the same redaction labels globally.
    class GlobalMapping
      # Creates a global mapping from individual filter results
      #
      # @param individual_results [Array<Result>] Array of individual filter results
      # @return [Hash] Inverted mapping from filter labels to original values
      def self.from_results(individual_results)
        new.build_from_results(individual_results)
      end

      # Creates a new GlobalMapping instance
      def initialize
        @mapping = {}
        @sequence = LabelSequence.new
      end

      # Builds the global mapping by processing all individual results
      #
      # @param individual_results [Array<Result>] Array of individual filter results
      # @return [Hash] Inverted mapping from filter labels to original values
      def build_from_results(individual_results)
        individual_results.each { |result| process_result(result) if result.sensitive? }

        mapping.invert
      end

      private

      attr_reader :mapping
      attr_reader :sequence

      # Processes a single result, adding new values to the global mapping
      #
      # @param result [Result] Individual filter result to process
      def process_result(result)
        result.mapping.each do |individual_key, value|
          next if mapping.key?(value)

          label_type = Category.type_from_key(individual_key)
          mapping[value] = sequence.next_label(label_type)
        end
      end
    end
  end
end
