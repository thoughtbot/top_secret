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

# TopSecret filters sensitive information from free text before it's sent to external services or APIs, such as chatbots and LLMs.
#
# @!attribute [rw] model_path
#   @return [String] the path to the MITIE NER model
#
# @!attribute [rw] min_confidence_score
#   @return [Float] the minimum confidence score required for NER matches
#
# @!attribute [rw] default_filters
#   @return [ActiveSupport::OrderedOptions] a set of default filters used to identify sensitive data
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
