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
    end

    def self.filter(input)
      new(input).filter
    end

    def filter
      emails = input.scan(EMAIL_REGEX)
      credit_cards = input.scan(CREDIT_CARD_REGEX_DELIMITERS) + input.scan(CREDIT_CARD_REGEX)
      ssns = input.scan(SSN_REGEX)
      phone_numbers = input.scan(PHONE_REGEX)

      emails.uniq.each.with_index(1) do |email, index|
        filter = "EMAIL_#{index}"
        output.gsub! email, "[#{filter}]"
      end

      credit_cards.uniq.each.with_index(1) do |credit_card, index|
        filter = "CREDIT_CARD_#{index}"
        output.gsub! credit_card, "[#{filter}]"
      end

      ssns.each.with_index(1) do |ssn, index|
        filter = "SSN_#{index}"
        output.gsub! ssn, "[#{filter}]"
      end

      phone_numbers.each.with_index(1) do |phone_number, index|
        filter = "PHONE_NUMBER_#{index}"
        output.gsub! phone_number, "[#{filter}]"
      end

      Result.new(input, output)
    end

    private

    attr_reader :output, :input
  end

  class Result
    attr_reader :input, :output

    def initialize(input, output)
      @input = input
      @output = output
    end
  end
end
