# frozen_string_literal: true

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

    def emails
      email_mapping.values
    end

    def emails?
      emails.any?
    end

    def email_mapping
      mapping.select { |key, _| key.start_with? "EMAIL_" }
    end
  end
end
