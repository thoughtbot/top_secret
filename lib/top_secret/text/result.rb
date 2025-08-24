# frozen_string_literal: true

module TopSecret
  class Text
    # Holds the result of a redaction operation.
    class Result # TODO: Rename to FilterResult
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
    end
  end
end
