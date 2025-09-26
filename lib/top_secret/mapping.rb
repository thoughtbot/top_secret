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
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      mapping_methods.include?(method_name) ||
        pluralized_methods.include?(method_name) ||
        predicate_methods.include?(method_name) ||
        super
    end

    def types
      @types ||= mapping.keys.map do |key|
        key.to_s.split("_").first.downcase
      end.uniq.map(&:to_sym)
    end

    private

    def stringified_types
      types.map(&:to_s)
    end

    def pluralized_methods
      @pluralized_methods ||= stringified_types.map(&:pluralize).map(&:to_sym)
    end

    def predicate_methods
      @predicate_methods ||= pluralized_methods.map { :"#{_1}?" }
    end

    def mapping_methods
      @mapping_methods ||= stringified_types.map { :"#{_1}_mapping" }
    end

    def build_mapping_method_from(method_name)
      type = method_name.to_s.split("mapping").first.upcase

      mapping.select { |key, _| key.start_with? type }
    end

    def build_plural_method_from(method_name)
      mapping_method = (method_name.to_s.singularize + "_mapping").to_sym

      send(mapping_method).values
    end

    def build_predicate_method_from(method_name)
      plural_method = method_name.to_s.chomp("?").to_sym

      send(plural_method).any?
    end
  end
end
