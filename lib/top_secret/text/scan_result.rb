# frozen_string_literal: true

module TopSecret
  class Text
    # Holds the result of a scan operation.
    class ScanResult
      include Mapping

      # @return [Hash] Mapping of redacted labels to matched values
      attr_reader :mapping

      # @param mapping [Hash] Map of labels to matched values
      def initialize(mapping)
        @mapping = mapping
      end
    end
  end
end
