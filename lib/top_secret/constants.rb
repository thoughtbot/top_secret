# frozen_string_literal: true

module TopSecret
  CREDIT_CARD_REGEX = /
    \b[3456]\d{15}\b |
    \b[3456]\d{3}(?:[\s+-]\d{4}){3}\b
  /x
  # Modified from URI::MailTo::EMAIL_REGEXP
  EMAIL_REGEX = %r{[a-zA-Z0-9.!\#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*}
  PHONE_REGEX = /\b(?:\+\d{1,2}\s)?\(?\d{3}\)?[\s+.-]\d{3}[\s+.-]\d{4}\b/
  SSN_REGEX = /\b\d{3}[\s+-]\d{2}[\s+-]\d{4}\b/
  MIN_CONFIDENCE_SCORE = 0.5
end
