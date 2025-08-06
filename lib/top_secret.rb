# frozen_string_literal: true

require_relative "top_secret/version"
require "active_support/configurable"
require "active_support/ordered_options"
require "mitie"

module TopSecret
  include ActiveSupport::Configurable

  CREDIT_CARD_REGEX = /
    \b[3456]\d{15}\b |
    \b[3456]\d{3}(?:[\s+-]\d{4}){3}\b
  /x
  # Modified from URI::MailTo::EMAIL_REGEXP
  EMAIL_REGEX = %r{[a-zA-Z0-9.!\#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*}
  PHONE_REGEX = /\b(?:\+\d{1,2}\s)?\(?\d{3}\)?[\s+.-]\d{3}[\s+.-]\d{4}\b/
  SSN_REGEX = /\b\d{3}[\s+-]\d{2}[\s+-]\d{4}\b/
  MIN_CONFIDENCE_SCORE = 0.5

  module Filters
    class Regex
      attr_reader :label

      def initialize(label:, regex:)
        @label = label
        @regex = regex
      end

      def call(input)
        input.scan(regex)
      end

      private

      attr_reader :regex
    end

    class NER
      attr_reader :label

      def initialize(label:, tag:, min_confidence_score: nil)
        @label = label
        @tag = tag.upcase.to_s
        @min_confidence_score = min_confidence_score || TopSecret.min_confidence_score
      end

      def call(entities)
        tags = entities.filter { _1.fetch(:tag) == tag && _1.fetch(:score) >= min_confidence_score }
        tags.map { _1.fetch(:text) }
      end

      private

      attr_reader :tag, :min_confidence_score
    end
  end

  config_accessor :model_path, default: "ner_model.dat"
  config_accessor :min_confidence_score, default: MIN_CONFIDENCE_SCORE

  # TODO: How might we resolve duplicate labels?
  config_accessor :default_filters do
    options = ActiveSupport::OrderedOptions.new
    options.credit_card_filter = TopSecret::Filters::Regex.new(label: "CREDIT_CARD", regex: CREDIT_CARD_REGEX)
    options.email_filter = TopSecret::Filters::Regex.new(label: "EMAIL", regex: EMAIL_REGEX)
    options.phone_number_filter = TopSecret::Filters::Regex.new(label: "PHONE_NUMBER", regex: PHONE_REGEX)
    options.ssn_filter = TopSecret::Filters::Regex.new(label: "SSN", regex: SSN_REGEX)
    options.people_filter = TopSecret::Filters::NER.new(label: "PERSON", tag: :person)
    options.location_filter = TopSecret::Filters::NER.new(label: "LOCATION", tag: :location)

    options
  end

  class Error < StandardError; end

  class Text
    def initialize(input, filters: TopSecret.default_filters)
      @input = input
      @output = input.dup
      @mapping = {}

      @model = Mitie::NER.new(TopSecret.model_path)
      @doc = @model.doc(@output)
      @entities = @doc.entities

      @filters = filters
    end

    def self.filter(input, filters: {})
      new(input, filters:).filter
    end

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

    attr_reader :input, :output, :mapping, :entities, :filters

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
