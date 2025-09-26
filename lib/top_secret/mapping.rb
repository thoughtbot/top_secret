# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module TopSecret
  module Mapping
    # @return [Boolean] Whether sensitive information was found
    def sensitive?
      mapping.any?
    end

    # @return [Boolean] Whether sensitive information was not found
    def safe?
      !sensitive?
    end

    def method_missing(method_name)
      types = mapping.keys.map do |key|
        key.to_s.split("_").first.downcase
      end

      mapping_methods = types.uniq.map do |type|
        (type + "_mapping").to_sym
      end

      plural_types = types.uniq.map(&:pluralize).map(&:to_sym)

      predicate_types = plural_types.map do |plural_type|
        (plural_type.to_s + "?").to_sym
      end

      if (foo = mapping_methods.select { _1 == method_name }.first)
        self.class.define_method(foo) do
          mapping.select { |key, _| key.start_with? method_name.to_s.split("mapping").first.upcase }
        end

        send(method_name)
      elsif (foo = plural_types.select { _1 == method_name }.first)
        self.class.define_method(foo) do
          email_mapping.values
        end

        send(method_name)
      elsif (foo = predicate_types.select { _1 == method_name }.first)
        self.class.define_method(foo) do
          emails.any?
        end

        send(method_name)
      else
        super
      end
    end

    def people
      person_mapping.values
    end

    def people?
      people.any?
    end

    def person_mapping
      mapping.select { |key, _| key.start_with? "PERSON_" }
    end
  end
end
