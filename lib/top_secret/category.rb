# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module TopSecret
  # Represents a category of sensitive information (e.g., email, person, credit_card).
  #
  # Each category derives a set of method names from its type and can resolve
  # those methods against a mapping to return filtered results.
  #
  # @example
  #   category = TopSecret::Category.new(:email)
  #   category.plural          # => :emails
  #   category.predicate       # => :emails?
  #   category.mapping_method  # => :email_mapping
  class Category
    MAPPING_SUFFIX = "_mapping"

    # @return [String] the category type (e.g., "email", "credit_card")
    attr_reader :type

    # Builds categories from a mapping's keys and a list of filters.
    #
    # @param mapping [Hash] the label-to-value mapping (e.g., +{EMAIL_1: "ralph@example.com"}+)
    # @param filters [Array<TopSecret::Filters::Regex, TopSecret::Filters::NER>] active filters
    # @return [Array<Category>] unique categories derived from the mapping and filters
    def self.from(mapping:, filters:)
      types_from_mapping = mapping.keys.map { |key| type_from_key(key).downcase }

      types_from_filters = filters.map { |filter| filter.label.downcase }

      (types_from_mapping + types_from_filters).uniq.map { |type| new(type) }
    end

    # Extracts the label type from a key symbol.
    #
    # @param key [Symbol] a label key (e.g., :EMAIL_1, :CREDIT_CARD_2)
    # @return [String] the label type (e.g., "EMAIL", "CREDIT_CARD")
    def self.type_from_key(key)
      key.to_s.rpartition(TopSecret::LABEL_DELIMITER).first
    end

    # @param type [String, Symbol] the category type
    def initialize(type)
      @type = type.to_s
    end

    # Whether this category recognizes the given method name.
    #
    # @param method_name [Symbol] the method name to check
    # @return [Boolean]
    def respond_to_method?(method_name)
      method_names.include?(method_name)
    end

    # @return [Symbol] the pluralized type (e.g., +:emails+)
    def plural
      @type.pluralize.to_sym
    end

    # @return [Symbol] the predicate method name (e.g., +:emails?+)
    def predicate
      :"#{plural}?"
    end

    # @return [Symbol] the mapping method name (e.g., +:email_mapping+)
    def mapping_method
      if @type.end_with?(MAPPING_SUFFIX)
        :"#{@type.pluralize}#{MAPPING_SUFFIX}"
      else
        :"#{@type}#{MAPPING_SUFFIX}"
      end
    end

    # @return [Symbol] the mapping predicate method name (e.g., +:email_mapping?+)
    def mapping_predicate
      :"#{mapping_method}?"
    end

    # Whether the mapping contains any keys belonging to this category.
    #
    # @param mapping [Hash] the label-to-value mapping
    # @return [Boolean]
    def matches?(mapping)
      mapping.any? { |key, _| key.to_s.match?(key_pattern) }
    end

    # Resolves a method name against the mapping, returning the appropriate result.
    #
    # @param method_name [Symbol] one of {#plural}, {#predicate}, {#mapping_method}, or {#mapping_predicate}
    # @param mapping [Hash] the label-to-value mapping
    # @return [Hash, Array, Boolean] filtered mapping, values, or boolean depending on the method
    # @raise [ArgumentError] if the method name is not recognized
    def resolve(method_name, mapping)
      filtered = filter_mapping(mapping)

      case method_name
      when mapping_method then filtered
      when plural then filtered.values
      when predicate, mapping_predicate then filtered.any?
      else
        raise ArgumentError, "#{method_name} is not a recognized method for category '#{@type}'"
      end
    end

    private

    def method_names
      @method_names ||= Set[plural, predicate, mapping_method, mapping_predicate].freeze
    end

    def key_pattern
      @key_pattern ||= /\A#{Regexp.escape(@type.upcase)}#{Regexp.escape(TopSecret::LABEL_DELIMITER)}\d+\z/
    end

    def filter_mapping(mapping)
      mapping.select { |key, _| key.to_s.match?(key_pattern) }
    end
  end
end
