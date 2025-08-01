# frozen_string_literal: true

require_relative "top_secret/version"

module TopSecret
  # Modified from URI::MailTo::EMAIL_REGEXP
  EMAIL_REGEX = %r{[a-zA-Z0-9.!\#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*}

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

      emails.uniq.each.with_index(1) do |email, index|
        filter = "EMAIL_#{index}"
        output.gsub! email, "[#{filter}]"
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
