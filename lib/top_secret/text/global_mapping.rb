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
        @label_counters = {}
      end

      # Builds the global mapping by processing all individual results
      #
      # @param individual_results [Array<Result>] Array of individual filter results
      # @return [Hash] Inverted mapping from filter labels to original values
      def build_from_results(individual_results)
        individual_results.each { |result| process_result(result) }

        mapping.invert
      end

      private

      attr_reader :mapping
      attr_reader :label_counters

      # Processes a single result, adding new values to the global mapping
      #
      # @param result [Result] Individual filter result to process
      def process_result(result)
        result.mapping.each do |individual_key, value|
          next if mapping.key?(value)

          mapping[value] = generate_global_key(individual_key)
        end
      end

      # Generates a consistent global key for a given individual key
      #
      # @param individual_key [Symbol] The individual key from a filter result
      # @return [Symbol] The global key with consistent numbering
      def generate_global_key(individual_key)
        # TODO: This assumes labels are formatted consistently.
        # We need to account for the following for the case where a label could begin with an "_"
        label_type = individual_key.to_s.rpartition("_").first

        label_counters[label_type] ||= 0
        label_counters[label_type] += 1
        :"#{label_type}_#{label_counters[label_type]}"
      end
    end
  end
end
