# frozen_string_literal: true

module TopSecret
  module Filters
    # Applies regex-based filtering to extract matching text from input.
    class Regex
      # @return [String] The label applied to matching content
      attr_reader :label

      # @param label [String] The label for redacted content
      # @param regex [Regexp] The regular expression used to match content
      def initialize(label:, regex:)
        @label = label
        @regex = regex
      end

      # Applies the regex to the input and returns all matches.
      #
      # @param input [String] The input text to scan
      # @return [Array<String>] All matches found
      def call(input)
        input.scan(regex)
      end

      private

      # @return [Regexp] The regular expression used for matching
      # @private
      attr_reader :regex
    end
  end
end
