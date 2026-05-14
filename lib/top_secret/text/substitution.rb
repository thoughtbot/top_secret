# frozen_string_literal: true

module TopSecret
  class Text
    # Replaces matched values in text with their label placeholders.
    #
    # When a value is matched by a single filter, every occurrence is replaced
    # with that label. When a value is matched by multiple filters, occurrences
    # are labeled in filter order; if there are more labels than occurrences,
    # the later labels win (preserving "custom filter overrides default" semantics).
    class Substitution
      def initialize(mapping)
        @mapping = mapping
      end

      def apply!(output)
        return output if labels_by_value.empty?

        substitute_single_label_values!(output)
        substitute_multi_label_values!(output)
        output
      end

      private

      attr_reader :mapping

      def labels_by_value
        @labels_by_value ||= mapping.each_with_object({}) do |(filter, value), hash|
          (hash[value] ||= []) << "[#{filter}]"
        end
      end

      def single_label_values
        labels_by_value.select { |_, labels| labels.one? }
      end

      def multi_label_values
        labels_by_value.reject { |_, labels| labels.one? }
      end

      def substitute_single_label_values!(output)
        return if single_label_values.empty?

        value_to_label = single_label_values.transform_values(&:first)
        output.gsub!(Regexp.union(value_to_label.keys), value_to_label)
      end

      def substitute_multi_label_values!(output)
        multi_label_values.each do |value, labels|
          labels_for_each_occurrence(value, labels, output).each do |label|
            output.sub!(value, label)
          end
        end
      end

      def labels_for_each_occurrence(value, labels, output)
        occurrences = output.scan(value).size
        return labels.last(1) if occurrences.zero?

        labels.last(occurrences)
      end
    end
  end
end
