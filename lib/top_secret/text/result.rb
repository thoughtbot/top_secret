# frozen_string_literal: true

module TopSecret
  class Text
    # Holds the result of a redaction operation.
    class Result # TODO: Rename to FilterResult
      # @return [String] The original unredacted input
      attr_reader :input

      # @return [String] The redacted output
      attr_reader :output

      delegate :mapping, to: :scan_result

      # @param input [String] The original text
      # @param output [String] The redacted text
      # @param mapping [Hash] Map of labels to matched values
      def initialize(input, output, scan_result)
        @input = input
        @output = output
        @scan_result = scan_result
      end

      private

      attr_reader :scan_result
    end
  end
end
