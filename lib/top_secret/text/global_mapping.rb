# frozen_string_literal: true

module TopSecret
  class Text
    class GlobalMapping
      def self.from_results(individual_results)
        global_mapping = {}
        label_counters = {}

        individual_results.each do |result|
          result.mapping.each do |individual_key, value|
            next if global_mapping.key?(value)

            # TODO: This assumes labels are formatted consistently.
            # We need to account for the following for the case where a label could begin with an "_"
            label_type = individual_key.to_s.rpartition("_").first

            label_counters[label_type] ||= 0
            label_counters[label_type] += 1
            global_key = :"#{label_type}_#{label_counters[label_type]}"

            global_mapping[value] = global_key
          end
        end

        global_mapping
      end
    end
  end
end
