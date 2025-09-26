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

      if mapping_methods.select { _1 == method_name }.first == :email_mapping
        self.class.define_method(:email_mapping) do
          mapping.select { |key, _| key.start_with? method_name.to_s.split("mapping").first.upcase }
        end

        send(method_name)
      elsif plural_types.select { _1 == method_name }.first == :emails
        self.class.define_method(:emails) do
          email_mapping.values
        end

        send(method_name)
      elsif method_name == :emails?
        self.class.define_method(:emails?) do
          emails.any?
        end

        send(method_name)
      else
        super
      end
    end

    # def emails
    #   email_mapping.values
    # end

    # def emails?
    #   emails.any?
    # end

    # def email_mapping
    #   mapping.select { |key, _| key.start_with? "EMAIL_" }
    # end

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
