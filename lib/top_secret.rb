# frozen_string_literal: true

# dependencies
require "active_support/configurable"
require "active_support/ordered_options"
require "mitie"

# modules
require_relative "top_secret/version"
require_relative "top_secret/constants"
require_relative "top_secret/filters/ner"
require_relative "top_secret/filters/regex"
require_relative "top_secret/error"
require_relative "top_secret/result"
require_relative "top_secret/text"

module TopSecret
  include ActiveSupport::Configurable

  config_accessor :model_path, default: "ner_model.dat"
  config_accessor :min_confidence_score, default: MIN_CONFIDENCE_SCORE

  config_accessor :default_filters do
    options = ActiveSupport::OrderedOptions.new
    options.credit_card_filter = TopSecret::Filters::Regex.new(label: "CREDIT_CARD", regex: CREDIT_CARD_REGEX)
    options.email_filter = TopSecret::Filters::Regex.new(label: "EMAIL", regex: EMAIL_REGEX)
    options.phone_number_filter = TopSecret::Filters::Regex.new(label: "PHONE_NUMBER", regex: PHONE_REGEX)
    options.ssn_filter = TopSecret::Filters::Regex.new(label: "SSN", regex: SSN_REGEX)
    options.people_filter = TopSecret::Filters::NER.new(label: "PERSON", tag: :person)
    options.location_filter = TopSecret::Filters::NER.new(label: "LOCATION", tag: :location)

    options
  end
end
