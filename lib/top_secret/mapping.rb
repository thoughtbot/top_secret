# frozen_string_literal: true

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
    # @return [Boolean] Whether sensitive information was found
    def sensitive?
      mapping.any?
    end

    # @return [Boolean] Whether sensitive information was not found
    def safe?
      !sensitive?
    end

    def method_missing(method_name, *args, &block)
      category = category_for(method_name)

      if category
        result = category.resolve(method_name, mapping)
        define_singleton_method(method_name) { result }
        result
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      category_for(method_name) || super
    end

    # Returns categories that have matches in the mapping.
    #
    # @return [Array<Symbol>] List of categories with matches
    def categories
      @categories ||= category_objects.select { |c| c.matches?(mapping) }.map { |c| c.type.to_sym }
    end

    private

    def category_objects
      @category_objects ||= Category.from(mapping:, filters: default_filters)
    end

    def category_for(method_name)
      category_objects.find { |c| c.respond_to_method?(method_name) }
    end

    def default_filters
      @default_filters ||= [
        TopSecret.credit_card_filter,
        TopSecret.email_filter,
        TopSecret.phone_number_filter,
        TopSecret.ssn_filter,
        TopSecret.people_filter,
        TopSecret.location_filter
      ].compact
    end
  end
end
