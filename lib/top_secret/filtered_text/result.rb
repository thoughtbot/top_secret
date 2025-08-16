# frozen_string_literal: true

module TopSecret
  class FilteredText
    # Result object returned by FilteredText restoration operations.
    #
    # Contains the restored text along with tracking information about which
    # placeholders were successfully restored and which remain unrestored.
    class Result
      # @return [String] The text with placeholders restored to original values
      attr_reader :output

      # @return [Array<String>] Array of placeholder strings that could not be restored
      attr_reader :unrestored

      # @return [Array<String>] Array of placeholder strings that were successfully restored
      attr_reader :restored

      # @param output [String] The restored text
      # @param unrestored [Array<String>] Placeholders that could not be restored
      # @param restored [Array<String>] Placeholders that were successfully restored
      def initialize(output, unrestored, restored)
        @output = output
        @unrestored = unrestored
        @restored = restored
      end
    end
  end
end
