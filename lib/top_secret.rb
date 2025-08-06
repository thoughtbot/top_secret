# frozen_string_literal: true

require_relative "top_secret/version"
require "active_support/configurable"
require "mitie"

module TopSecret
  include ActiveSupport::Configurable

  config_accessor :model_path, default: "ner_model.dat"
  config_accessor :min_confidence_score, default: 0.5

  CREDIT_CARD_REGEX = /
    \b[3456]\d{15}\b |
    \b[3456]\d{3}(?:[\s+-]\d{4}){3}\b
  /x
  # Modified from URI::MailTo::EMAIL_REGEXP
  EMAIL_REGEX = %r{[a-zA-Z0-9.!\#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*}
  PHONE_REGEX = /\b(?:\+\d{1,2}\s)?\(?\d{3}\)?[\s+.-]\d{3}[\s+.-]\d{4}\b/
  SSN_REGEX = /\b\d{3}[\s+-]\d{2}[\s+-]\d{4}\b/

  class Error < StandardError; end

  class Text
    def initialize(input, min_confidence_score: TopSecret.min_confidence_score, model_path: TopSecret.model_path)
      @input = input
      @output = input.dup
      @mapping = {}

      @model = Mitie::NER.new(model_path)
      @doc = @model.doc(@output)
      @entities = @doc.entities
      @min_confidence_score = min_confidence_score
    end

    def self.filter(input, min_confidence_score: TopSecret.min_confidence_score, model_path: TopSecret.model_path)
      new(input, model_path:, min_confidence_score:).filter
    end

    def filter
      build_mapping(credit_cards, label: "CREDIT_CARD")
      build_mapping(emails, label: "EMAIL")
      build_mapping(phone_numbers, label: "PHONE_NUMBER")
      build_mapping(ssns, label: "SSN")
      build_mapping(people, label: "PERSON")
      build_mapping(locations, label: "LOCATION")
      substitute_text

      Result.new(input, output, mapping)
    end

    private

    attr_reader :input, :output, :mapping, :entities, :min_confidence_score

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
      input.scan(CREDIT_CARD_REGEX)
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

    def people
      tags = entities.filter { _1.fetch(:tag) == "PERSON" && _1.fetch(:score) >= min_confidence_score }
      tags.map { _1.fetch(:text) }
    end

    def locations
      tags = entities.filter { _1.fetch(:tag) == "LOCATION" && _1.fetch(:score) >= min_confidence_score }
      tags.map { _1.fetch(:text) }
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
