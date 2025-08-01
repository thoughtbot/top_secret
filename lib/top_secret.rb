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
      @output = input.dup
    end

    def self.filter(input)
      new(input).filter
    end

    def filter
      output = DEFAULT_FILTERS.reduce(input.dup) do |input, params|
        Filter::Regex.new(input:, **params).filter
      end

      Result.new(input, output)
    end

    private

    attr_reader :input
  end

  class Result
    attr_reader :input, :output

    def initialize(input, output)
      @input = input
      @output = output
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

        values.uniq.each.with_index(1) do |value, index|
          filter = "#{label}_#{index}"
          input.gsub! value, "[#{filter}]"
        end

        input
      end
    end
  end
end
