# frozen_string_literal: true

module TopSecret
  class Text
    # Holds the result of a scan operation.
    class ScanResult
      # @return [Hash] Mapping of redacted labels to matched values
      attr_reader :mapping

      # @param mapping [Hash] Map of labels to matched values
      def initialize(mapping)
        @mapping = mapping
      end

      # @return [Boolean] Whether sensitive information was found
      def sensitive?
        mapping.any?
      end
    end
  end
end
