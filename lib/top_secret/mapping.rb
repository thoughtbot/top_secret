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

      if mapping_methods.select { _1 == method_name }.first
        self.class.define_method(method_name) do
          mapping.select { |key, _| key.start_with? method_name.to_s.split("mapping").first.upcase }
        end

        send(method_name)
      elsif plural_types.select { _1 == method_name }.first
        mapping_method = (method_name.to_s.singularize + "_mapping").to_sym
        self.class.define_method(method_name) do
          send(mapping_method).values
        end

        send(method_name)
      elsif predicate_types.select { _1 == method_name }.first
        plural_method = method_name.to_s.chomp("?").to_sym
        self.class.define_method(method_name) do
          send(plural_method).any?
        end

        send(method_name)
      else
        super
      end
    end
  end
end
