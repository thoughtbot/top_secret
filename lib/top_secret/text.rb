# frozen_string_literal: true

module TopSecret
  # Processes text to identify and redact sensitive information using configured filters.
  class Text
    # @param input [String] The original text to be filtered
    # @param filters [Hash, nil] Optional set of filters to override the defaults
    # @param custom_filters [Array] Additional custom filters to apply
    def initialize(input, filters: {}, custom_filters: [])
      @input = input
      @output = input.dup
      @mapping = {}

      @model = Mitie::NER.new(TopSecret.model_path)
      @doc = @model.doc(@output)
      @entities = @doc.entities

      @filters = filters
      @custom_filters = custom_filters || []
    end

    # Convenience method to create an instance and filter input
    #
    # @param input [String] The text to filter
    # @param filters [Hash] Optional filters to override defaults
    # @param custom_filters [Array] Additional custom filters to apply
    # @return [Result] The filtered result
    def self.filter(input, custom_filters: [], **filters)
      new(input, filters: filters, custom_filters: custom_filters).filter
    end

    # Applies configured filters to the input, redacting matches and building a mapping.
    #
    # @return [Result] Contains original input, redacted output, and mapping of labels to values
    # @raise [Error] If an unsupported filter is encountered
    def filter
      all_filters.each do |filter|
        next if filter.nil?

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

    # @return [Array] Custom filters to apply
    attr_reader :custom_filters

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

    # Collects all filters to apply: default filters with overrides plus custom filters
    #
    # @return [Array] Array of filter objects to apply
    def all_filters
      # Get current default filters
      default_filters = {
        credit_card_filter: TopSecret.credit_card_filter,
        email_filter: TopSecret.email_filter,
        phone_number_filter: TopSecret.phone_number_filter,
        ssn_filter: TopSecret.ssn_filter,
        people_filter: TopSecret.people_filter,
        location_filter: TopSecret.location_filter
      }

      # Apply any overrides from the filters parameter
      merged_filters = default_filters.merge(filters)

      # Combine default/override filters with custom filters
      merged_filters.values.compact + custom_filters
    end
  end
end
