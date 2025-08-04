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
    def initialize(input)
      @input = input
      @output = input.dup
      @mapping = {}
    end

    def self.filter(input)
      new(input).filter
    end

    def filter
      build_mapping(credit_cards, label: "CREDIT_CARD")
      build_mapping(emails, label: "EMAIL")
      build_mapping(phone_numbers, label: "PHONE_NUMBER")
      build_mapping(ssns, label: "SSN")
      substitute_text

      Result.new(input, output, mapping)
    end

    private

    attr_reader :input, :output, :mapping

    def build_mapping(values, label:)
      values.uniq.each.with_index(1) do |value, index|
        filter = "#{label}_#{index}"
        mapping.merge!({filter.to_sym => value})
      end
    end

    def substitute_text
      mapping.each do |filter, value|
        output.gsub! value, "[#{filter}]"
      end
    end

    def credit_cards
      input.scan(CREDIT_CARD_REGEX_DELIMITERS) + input.scan(CREDIT_CARD_REGEX)
    end

    def emails
      input.scan(EMAIL_REGEX)
    end

    def phone_numbers
      input.scan(PHONE_REGEX)
    end

    def ssns
      input.scan(SSN_REGEX)
    end
  end

  class Result
    attr_reader :input, :output, :mapping

    def initialize(input, output, mapping)
      @input = input
      @output = output
      @mapping = mapping
    end
  end
end
