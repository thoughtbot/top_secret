# frozen_string_literal: true

module TopSecret
  # Processes text to identify and redact sensitive information using configured filters.
  class Text
    # @param input [String] The original text to be filtered
    # @param filters [Hash, nil] Optional set of filters to override the defaults
    def initialize(input, filters: TopSecret.default_filters)
      @input = input
      @output = input.dup
      @mapping = {}

      @model = Mitie::NER.new(TopSecret.model_path)
      @doc = @model.doc(@output)
      @entities = @doc.entities

      @filters = filters
    end

    # Convenience method to create an instance and filter input
    #
    # @param input [String] The text to filter
    # @param filters [Hash] Optional filters to override defaults
    # @return [Result] The filtered result
    def self.filter(input, filters: {})
      new(input, filters:).filter
    end

    # Applies configured filters to the input, redacting matches and building a mapping.
    #
    # @return [Result] Contains original input, redacted output, and mapping of labels to values
    # @raise [Error] If an unsupported filter is encountered
    def filter
      TopSecret.default_filters.merge(filters).compact.each_value do |filter|
        values = case filter
        when TopSecret::Filters::Regex
          filter.call(input)
        when TopSecret::Filters::NER
          filter.call(entities)
        else
          raise Error, "Unsupported filter. Expected TopSecret::Filters::Regex or TopSecret::Filters::NER, but got #{filter.class}"
        end
        build_mapping(values, label: filter.label)
      end

      substitute_text

      Result.new(input, output, mapping)
    end

    private

    # @return [String] Original unredacted input text
    attr_reader :input

    # @return [String] Output with sensitive information redacted
    attr_reader :output

    # @return [Hash] Mapping from redaction labels to original values
    attr_reader :mapping

    # @return [Array<Hash>] Named entities extracted by MITIE
    attr_reader :entities

    # @return [Hash] Active filters used for redaction
    attr_reader :filters

    # Builds the mapping of label keys to matched values, indexed uniquely.
    #
    # @param values [Array<String>] Values matched by a filter
    # @param label [String] Label identifying the filter type
    # @return [void]
    def build_mapping(values, label:)
      values.uniq.each.with_index(1) do |value, index|
        filter = "#{label}_#{index}"
        mapping.merge!({filter.to_sym => value})
      end
    end

    # Substitutes matched values in the output text with their label placeholders.
    #
    # @return [void]
    def substitute_text
      mapping.each do |filter, value|
        output.gsub! value, "[#{filter}]"
      end
    end
  end
end
