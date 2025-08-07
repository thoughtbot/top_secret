# frozen_string_literal: true

module TopSecret
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
end
