# frozen_string_literal: true

require_relative "top_secret/version"

module TopSecret
  CREDIT_CARD_REGEX = /\b[3456]\d{15}\b/
  CREDIT_CARD_REGEX_DELIMITERS = /\b[3456]\d{3}[\s+-]\d{4}[\s+-]\d{4}[\s+-]\d{4}\b/
  # Modified from URI::MailTo::EMAIL_REGEXP
  EMAIL_REGEX = %r{[a-zA-Z0-9.!\#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*}
  PHONE_REGEX = /\b(?:\+\d{1,2}\s)?\(?\d{3}\)?[\s+.-]\d{3}[\s+.-]\d{4}\b/
  SSN_REGEX = /\b\d{3}[\s+-]\d{2}[\s+-]\d{4}\b/

  class Error < StandardError; end

  class Text
    DEFAULT_FILTERS = [
      {label: "CREDIT_CARD", regex: [CREDIT_CARD_REGEX_DELIMITERS, CREDIT_CARD_REGEX]},
      {label: "EMAIL", regex: EMAIL_REGEX},
      {label: "PHONE_NUMBER", regex: PHONE_REGEX},
      {label: "SSN", regex: SSN_REGEX}
    ].freeze

    def initialize(input)
      @input = input
    end

    def self.filter(input)
      new(input).filter
    end

    def filter
      @output, @mapping = DEFAULT_FILTERS.reduce([input.dup, {}]) do |(input, accumulated_mapping), params|
        filtered, mapping = Filter::Regex.new(input:, **params).filter
        [filtered, accumulated_mapping.merge(mapping)]
      end

      Result.new(input, output, mapping)
    end

    private

    attr_reader :input, :output, :mapping
  end

  class Result
    attr_reader :input, :output, :mapping

    def initialize(input, output, mapping)
      @input = input
      @output = output
      @mapping = mapping
    end
  end

  module Filter
    class Regex
      attr_reader :label, :input, :regex

      def initialize(label:, input:, regex:)
        @label = label
        @input = input
        @regex = Array(regex)
      end

      def filter
        values = regex.flat_map { input.scan(_1) }

        mapping = {}

        values.uniq.each.with_index(1) do |value, index|
          filter = "#{label}_#{index}"
          input.gsub! value, "[#{filter}]"
          mapping[filter.to_sym] = value
        end

        [input, mapping]
      end
    end
  end
end
