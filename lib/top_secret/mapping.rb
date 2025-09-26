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
          mapping.select { |key, _| key.start_with? method_name.to_s.split("mapping").first.upcase }
        end

        send(method_name)
      elsif pluralized_methods.include? method_name
        mapping_method = (method_name.to_s.singularize + "_mapping").to_sym
        self.class.define_method(method_name) do
          send(mapping_method).values
        end

        send(method_name)
      elsif predicate_methods.include? method_name
        plural_method = method_name.to_s.chomp("?").to_sym
        self.class.define_method(method_name) do
          send(plural_method).any?
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

    private

    def types
      @types ||= mapping.keys.map do |key|
        key.to_s.split("_").first.downcase
      end
    end

    def pluralized_methods
      @pluralized_methods ||= types.uniq.map(&:pluralize).map(&:to_sym)
    end

    def predicate_methods
      @predicate_methods ||= pluralized_methods.map do |plural_type|
        (plural_type.to_s + "?").to_sym
      end
    end

    def mapping_methods
      @mapping_methods ||= types.uniq.map do |type|
        (type + "_mapping").to_sym
      end
    end
  end
end
