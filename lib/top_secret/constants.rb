# frozen_string_literal: true

module TopSecret
  # @return [String] The path to the NER model file
  MODEL_PATH = "ner_model.dat"

  # @return [Regexp] Matches credit card numbers
  CREDIT_CARD_REGEX = /
    \b[3456]\d{15}\b |
    \b[3456]\d{3}(?:[\s+-]\d{4}){3}\b
  /x

  # @return [Regexp] Matches valid email addresses
  EMAIL_REGEX = %r{
    [a-zA-Z0-9.!\#$%&'*+/=?^_`{|}~-]+@
    [a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?
    (?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*
  }x

  # @return [Regexp] Matches phone numbers with optional country code
  PHONE_REGEX = /\b(?:\+\d{1,2}\s)?\(?\d{3}\)?[\s+.-]?\d{3}[\s+.-]?\d{4}\b/

  # @return [Regexp] Matches Social Security Numbers in common formats
  SSN_REGEX = /\b\d{3}[\s+-]\d{2}[\s+-]\d{4}\b/

  # @return [Float] The minimum confidence score for NER filtering
  MIN_CONFIDENCE_SCORE = 0.5
end
