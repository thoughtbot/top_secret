# frozen_string_literal: true

module TopSecret
  class Text
    class GlobalMapping
      def self.from_results(individual_results)
        new.build_from_results(individual_results)
      end

      def initialize
        @mapping = {}
        @label_counters = {}
      end

      def build_from_results(individual_results)
        individual_results.each { |result| process_result(result) }

        mapping
      end

      private

      attr_accessor :mapping
      attr_reader :label_counters

      def process_result(result)
        result.mapping.each do |individual_key, value|
          next if mapping.key?(value)

          mapping[value] = generate_global_key(individual_key)
        end
      end

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
