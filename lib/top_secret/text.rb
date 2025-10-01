# frozen_string_literal: true

require "active_support/core_ext/hash/keys"
require_relative "null_model"
require_relative "text/result"
require_relative "text/batch_result"
require_relative "text/scan_result"
require_relative "text/global_mapping"

module TopSecret
  # Processes text to identify and redact sensitive information using configured filters.
  class Text
    # @param input [String] The original text to be filtered
    # @param filters [Hash, nil] Optional set of filters to override the defaults
    # @param custom_filters [Array] Additional custom filters to apply
    # @param model [Mitie::NER, nil] Optional pre-loaded MITIE model for performance
    def initialize(input, custom_filters: [], filters: {}, model: nil)
      @input = input
      @output = input.dup
      @mapping = {}

      @model = model || default_model

      @filters = filters
      @custom_filters = custom_filters
    end

    # Convenience method to create an instance and filter input
    #
    # @param input [String] The text to filter
    # @param filters [Hash] Optional filters to override defaults (only valid filter keys accepted)
    # @param custom_filters [Array] Additional custom filters to apply
    # @return [Result] The filtered result
    # @raise [ArgumentError] If invalid filter keys are provided
    def self.filter(input, custom_filters: [], **filters)
      new(input, filters:, custom_filters:).filter
    end

    # Filters multiple messages with globally consistent redaction labels
    #
    # Processes a collection of messages and ensures that identical sensitive values
    # receive the same redaction labels across all messages. This is useful when
    # processing conversation threads or document collections where consistency matters.
    #
    # @param messages [Array<String>] Array of text messages to filter
    # @param custom_filters [Array] Additional custom filters to apply
    # @param filters [Hash] Optional filters to override defaults (only valid filter keys accepted)
    # @return [BatchResult] Contains global mapping and array of Result objects with individual mappings
    # @raise [ArgumentError] If invalid filter keys are provided
    #
    # @example Basic usage
    #   messages = ["Contact john@test.com", "Email john@test.com again"]
    #   result = TopSecret::Text.filter_all(messages)
    #   result.items[0].output # => "Contact [EMAIL_1]"
    #   result.items[1].output # => "Email [EMAIL_1] again"
    #   result.items[0].mapping # => { EMAIL_1: "john@test.com" }
    #   result.mapping # => { EMAIL_1: "john@test.com" }
    #
    # @example With custom filters
    #   ip_filter = TopSecret::Filters::Regex.new(label: "IP", regex: /\d+\.\d+\.\d+\.\d+/)
    #   result = TopSecret::Text.filter_all(messages, custom_filters: [ip_filter])
    def self.filter_all(messages, custom_filters: [], **filters)
      Text::BatchResult.from_messages(messages, custom_filters:, **filters)
    end

    # Convenience method to scan input text for sensitive information without redacting it
    #
    # This method detects sensitive information using configured filters but does not modify
    # the original text. Use this when you only need to check if sensitive data exists or
    # get a mapping of what was found.
    #
    # @param input [String] The text to scan for sensitive information
    # @param filters [Hash] Optional filters to override defaults (only valid filter keys accepted)
    # @param custom_filters [Array] Additional custom filters to apply
    # @return [ScanResult] Contains mapping of found sensitive information and sensitive? flag
    # @raise [ArgumentError] If invalid filter keys are provided
    #
    # @example Basic scanning
    #   result = TopSecret::Text.scan("Contact john@example.com")
    #   result.sensitive? # => true
    #   result.mapping    # => {:EMAIL_1=>"john@example.com"}
    #
    # @example With custom filters
    #   ip_filter = TopSecret::Filters::Regex.new(label: "IP", regex: /\d+\.\d+\.\d+\.\d+/)
    #   result = TopSecret::Text.scan("Server IP: 192.168.1.1", custom_filters: [ip_filter])
    #   result.mapping # => {:IP_1=>"192.168.1.1"}
    #
    # @example Overriding default filters
    #   custom_email = TopSecret::Filters::Regex.new(label: "EMAIL_ADDR", regex: /\w+@\w+/)
    #   result = TopSecret::Text.scan("user@test.com", email_filter: custom_email)
    #   result.mapping # => {:EMAIL_ADDR_1=>"user@test.com"}
    def self.scan(input, custom_filters: [], **filters)
      new(input, filters:, custom_filters:).scan
    end

    # Scans the input text for sensitive information using configured filters
    #
    # This method applies all active filters to detect sensitive information but does not
    # redact the original text. It builds a mapping of found values and returns whether
    # any sensitive information was detected.
    #
    # @return [ScanResult] Contains mapping of found sensitive information and sensitive? flag
    # @raise [Error] If an unsupported filter is encountered
    # @raise [ArgumentError] If invalid filter keys are provided
    def scan
      @doc ||= model.doc(@output) if model
      @entities ||= doc.entities if model

      validate_filters!

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

      ScanResult.new(mapping)
    end

    # Applies configured filters to the input, redacting matches and building a mapping.
    #
    # @return [Result] Contains original input, redacted output, and mapping of labels to values
    # @raise [Error] If an unsupported filter is encountered
    # @raise [ArgumentError] If invalid filter keys are provided
    def filter
      scan_result = scan

      substitute_text if scan_result.sensitive?

      Text::Result.new(input, output, scan_result.mapping)
    end

    private

    # @return [String] Original unredacted input text
    attr_reader :input

    # @return [String] Output with sensitive information redacted
    attr_reader :output

    # @return [Hash] Mapping from redaction labels to original values
    attr_reader :mapping

    # @return [Object] The NER model (typically Mitie::NER or a test double)
    attr_reader :model

    # @return [Object] The document created from the output text (typically Mitie::Document or a test double)
    attr_reader :doc

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
      merged_filters.values.compact + TopSecret.custom_filters + custom_filters
    end

    # Merges default filters with user-provided filter overrides
    #
    # @return [Hash] Hash containing default filters with any user overrides applied
    # @private
    def merged_filters
      default_filters.merge(filters)
    end

    # Validates that all provided filter keys are recognized
    #
    # @return [void]
    # @raise [ArgumentError] If invalid filter keys are provided
    def validate_filters!
      merged_filters.assert_valid_keys(*default_filters.keys)
    end

    # Returns the default filters configuration hash
    #
    # @return [Hash] Hash containing all configured default filters, keyed by filter name
    # @private
    def default_filters
      {
        credit_card_filter: TopSecret.credit_card_filter,
        email_filter: TopSecret.email_filter,
        phone_number_filter: TopSecret.phone_number_filter,
        ssn_filter: TopSecret.ssn_filter,
        people_filter: TopSecret.people_filter,
        location_filter: TopSecret.location_filter
      }
    end

    # Creates the default model based on configuration.
    # Returns a MITIE NER model if a model path is configured, otherwise returns a null model.
    # If a shared_model is configured, it will be used instead of creating a new instance.
    #
    # @return [Mitie::NER, NullModel] The model instance to use for NER processing
    def default_model
      return TopSecret.shared_model if TopSecret.shared_model

      if TopSecret.model_path
        Mitie::NER.new(TopSecret.model_path)
      else
        NullModel.new
      end
    end
  end
end
