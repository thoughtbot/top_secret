# frozen_string_literal: true

# dependencies
require "active_support/core_ext/module/attribute_accessors"
require "mitie"

# modules
require_relative "top_secret/version"
require_relative "top_secret/constants"
require_relative "top_secret/category"
require_relative "top_secret/mapping"
require_relative "top_secret/filters/ner"
require_relative "top_secret/filters/regex"
require_relative "top_secret/error"
require_relative "top_secret/text"
require_relative "top_secret/filtered_text"

# TopSecret filters sensitive information from free text before it's sent to external services or APIs, such as chatbots and LLMs.
#
# @!attribute [rw] model_path
#   @return [String] the path to the MITIE NER model
#
# @!attribute [rw] min_confidence_score
#   @return [Float] the minimum confidence score required for NER matches
#
# @!attribute [rw] custom_filters
#   @return [Array] array of custom filters that can be configured
#
# @!attribute [rw] credit_card_filter
#   @return [TopSecret::Filters::Regex] filter for credit card numbers
#
# @!attribute [rw] email_filter
#   @return [TopSecret::Filters::Regex] filter for email addresses
#
# @!attribute [rw] phone_number_filter
#   @return [TopSecret::Filters::Regex] filter for phone numbers
#
# @!attribute [rw] ssn_filter
#   @return [TopSecret::Filters::Regex] filter for social security numbers
#
# @!attribute [rw] people_filter
#   @return [TopSecret::Filters::NER] filter for person names
#
# @!attribute [rw] location_filter
#   @return [TopSecret::Filters::NER] filter for location names
module TopSecret
  mattr_accessor :model_path, default: MODEL_PATH
  mattr_accessor :min_confidence_score, default: MIN_CONFIDENCE_SCORE

  mattr_accessor :custom_filters, default: []

  mattr_accessor :credit_card_filter, default: TopSecret::Filters::Regex.new(label: "CREDIT_CARD", regex: CREDIT_CARD_REGEX)
  mattr_accessor :email_filter, default: TopSecret::Filters::Regex.new(label: "EMAIL", regex: EMAIL_REGEX)
  mattr_accessor :phone_number_filter, default: TopSecret::Filters::Regex.new(label: "PHONE_NUMBER", regex: PHONE_REGEX)
  mattr_accessor :ssn_filter, default: TopSecret::Filters::Regex.new(label: "SSN", regex: SSN_REGEX)
  mattr_accessor :people_filter, default: TopSecret::Filters::NER.new(label: "PERSON", tag: :person)
  mattr_accessor :location_filter, default: TopSecret::Filters::NER.new(label: "LOCATION", tag: :location)

  class << self
    def configure
      yield self
    end
  end
end
