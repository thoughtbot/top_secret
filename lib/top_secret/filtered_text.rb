# frozen_string_literal: true

require_relative "filtered_text/result"

module TopSecret
  # Restores filtered text by substituting placeholders with original values.
  #
  # This class is used to reverse the filtering process, typically when processing
  # responses from external services like LLMs that may contain filtered placeholders.
  class FilteredText
    # @return [String] The text being processed for restoration
    attr_reader :output

    # @param filtered_text [String] Text containing filter placeholders like [EMAIL_1]
    # @param mapping [Hash] Hash mapping filter symbols to original values
    def initialize(filtered_text, mapping:)
      @mapping = mapping
      @output = filtered_text.dup
    end

    # Convenience method to restore filtered text in one call
    #
    # @param filtered_text [String] Text containing filter placeholders
    # @param mapping [Hash] Hash mapping filter symbols to original values
    # @return [Result] Contains restored text and tracking information
    #
    # @example Basic restoration
    #   mapping = {EMAIL_1: "john@example.com"}
    #   result = TopSecret::FilteredText.restore("Contact [EMAIL_1]", mapping: mapping)
    #   result.output # => "Contact john@example.com"
    #   result.restored # => ["[EMAIL_1]"]
    #   result.unrestored # => []
    def self.restore(filtered_text, mapping:)
      new(filtered_text, mapping:).restore
    end

    # Performs the restoration process
    #
    # Substitutes all found placeholders with their mapped values and tracks
    # which placeholders were successfully restored vs those that remain unrestored.
    #
    # @return [Result] Contains the restored text and tracking arrays
    def restore
      restored = []

      mapping.each do |filter, value|
        placeholder = build_placeholder(filter)

        if output.include? placeholder
          restored << placeholder
          output.gsub! placeholder, value
        end
      end

      unrestored = output.scan(/\[\w*_\d\]/)

      Result.new(output, unrestored, restored)
    end

    private

    # @return [Hash] Mapping from filter symbols to original values
    attr_reader :mapping

    # Builds a placeholder string from a filter symbol
    #
    # @param filter [Symbol] The filter symbol (e.g., :EMAIL_1)
    # @return [String] The placeholder string (e.g., "[EMAIL_1]")
    def build_placeholder(filter)
      "[#{filter}]"
    end
  end
end
