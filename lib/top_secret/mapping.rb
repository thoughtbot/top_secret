# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module TopSecret
  # Provides dynamic category methods for querying sensitive information by type.
  #
  # This module automatically generates methods for accessing sensitive information
  # organized by category (emails, credit cards, people, etc.). Methods are available
  # for all default filter types and any custom labels used in the mapping.
  #
  # @example Querying emails
  #   result = TopSecret::Text.filter("Contact ralph@example.com")
  #   result.emails?         # => true
  #   result.emails          # => ["ralph@example.com"]
  #   result.email_mapping   # => {:EMAIL_1=>"ralph@example.com"}
  #
  # @example With no matches
  #   result = TopSecret::Text.filter("No sensitive data")
  #   result.emails?         # => false
  #   result.emails          # => []
  #   result.email_mapping   # => {}
  #
  # @example Custom labels
  #   result = TopSecret::Text.filter(
  #     "user[at]example.com",
  #     email_filter: TopSecret::Filters::Regex.new(
  #       label: "EMAIL_ADDRESS",
  #       regex: /\w+\[at\]\w+\.\w+/
  #     )
  #   )
  #   result.email_addresses          # => ["user[at]example.com"]
  #   result.email_address_mapping    # => {:EMAIL_ADDRESS_1=>"user[at]example.com"}
  module Mapping
    MAPPING_SUFFIX = "_mapping"
    PREDICATE_SUFFIX = "?"

    # @return [Boolean] Whether sensitive information was found
    def sensitive?
      mapping.any?
    end

    # @return [Boolean] Whether sensitive information was not found
    def safe?
      !sensitive?
    end

    def method_missing(method_name, *args, &block)
      if mapping_methods.include? method_name
        self.class.define_method(method_name) do
          build_mapping_method_from method_name
        end

        send(method_name)
      elsif pluralized_methods.include? method_name
        self.class.define_method(method_name) do
          build_plural_method_from method_name
        end

        send(method_name)
      elsif predicate_methods.include? method_name
        self.class.define_method(method_name) do
          build_predicate_method_from method_name
        end

        send(method_name)
      elsif mapping_predicate_methods.include? method_name
        self.class.define_method(method_name) do
          build_mapping_predicate_method_from method_name
        end

        send(method_name)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      mapping_methods.include?(method_name) ||
        pluralized_methods.include?(method_name) ||
        predicate_methods.include?(method_name) ||
        mapping_predicate_methods.include?(method_name) ||
        super
    end

    # Returns all available types for category methods.
    #
    # Types are derived from both the mapping keys and default filters.
    # For example, with mapping `{EMAIL_1: "test@example.com"}`, the type is `:email`.
    # Default filter types (credit_card, email, phone_number, ssn, person, location)
    # are always available even when not present in the mapping.
    #
    # @return [Array<Symbol>] List of available types
    # @example
    #   result = TopSecret::Text.filter("ralph@example.com")
    #   result.types
    #   # => [:email, :credit_card, :phone_number, :ssn, :person, :location]
    def types
      @types ||= all_types.uniq.map(&:to_sym)
    end

    private

    def types_from_mapping
      mapping.keys.map do |key|
        parts = key.to_s.split(TopSecret::LABEL_DELIMITER).reject(&:empty?)
        parts[0...-1].join(TopSecret::LABEL_DELIMITER).downcase
      end
    end

    def types_from_filters
      default_filter_objects.map { |filter| filter.label.downcase }
    end

    def all_types
      types_from_mapping + types_from_filters
    end

    def default_filter_objects
      [
        TopSecret.credit_card_filter,
        TopSecret.email_filter,
        TopSecret.phone_number_filter,
        TopSecret.ssn_filter,
        TopSecret.people_filter,
        TopSecret.location_filter
      ].compact
    end

    def stringified_types
      types.map(&:to_s)
    end

    def pluralized_methods
      @pluralized_methods ||= stringified_types.map(&:pluralize).map(&:to_sym)
    end

    def predicate_methods
      @predicate_methods ||= pluralized_methods.map { :"#{_1}#{PREDICATE_SUFFIX}" }
    end

    def mapping_predicate_methods
      @mapping_predicate_methods ||= mapping_methods.map { :"#{_1}#{PREDICATE_SUFFIX}" }
    end

    def mapping_methods
      @mapping_methods ||= stringified_types.map do |type|
        if type.end_with?(MAPPING_SUFFIX)
          :"#{type.pluralize}#{MAPPING_SUFFIX}"
        else
          :"#{type}#{MAPPING_SUFFIX}"
        end
      end
    end

    def build_mapping_method_from(method_name)
      type_name = method_name.to_s.delete_suffix(MAPPING_SUFFIX)

      type_name = type_name.singularize if type_name.pluralize == type_name && type_name.singularize.end_with?(MAPPING_SUFFIX)

      type = type_name.upcase

      mapping.select { |key, _| key.start_with? type }
    end

    def build_plural_method_from(method_name)
      singular = method_name.to_s.singularize

      mapping_method = if singular.end_with?(MAPPING_SUFFIX)
        :"#{method_name}#{MAPPING_SUFFIX}"
      else
        :"#{singular}#{MAPPING_SUFFIX}"
      end

      send(mapping_method).values
    end

    def build_predicate_method_from(method_name)
      plural_method = method_name.to_s.chomp(PREDICATE_SUFFIX).to_sym

      send(plural_method).any?
    end

    def build_mapping_predicate_method_from(method_name)
      mapping_method = method_name.to_s.chomp(PREDICATE_SUFFIX).to_sym

      send(mapping_method).any?
    end
  end
end
