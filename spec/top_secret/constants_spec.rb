# frozen_string_literal: true

RSpec.describe TopSecret do
  describe "PHONE_REGEX" do
    phone_numbers = [
      "+1 415-555-1234",
      "(415) 555-1234",
      "415.555.1234",
      "415 555 1234",
      "415-555-1234",
      "4155551234"
    ]

    phone_numbers.each do |phone_number|
      it "matches #{phone_number}" do
        expect(phone_number).to match(described_class::PHONE_REGEX)
      end
    end
  end

  describe "CREDIT_CARD_REGEX" do
    credit_card_numbers = [
      "4123 4567 8901 2345",
      "5123-4567-8901-2346",
      "6123456789012347",
      "4123-4567-8901-2345",
      "5123 4567 8901 2346"
    ]

    credit_card_numbers.each do |cc_number|
      it "matches #{cc_number}" do
        expect(cc_number).to match(described_class::CREDIT_CARD_REGEX)
      end
    end
  end

  describe "EMAIL_REGEX" do
    email_addresses = [
      "user@example.com",
      "user.name+tag@example.co.uk",
      "USER_123@example.io",
      "user-name@example.travel",
      "first.last@subdomain.example.org"
    ]

    email_addresses.each do |email|
      it "matches #{email}" do
        expect(email).to match(described_class::EMAIL_REGEX)
      end
    end
  end

  describe "SSN_REGEX" do
    ssns = [
      "123-45-6789",
      "123 45 6789",
      "123+45+6789"
    ]

    ssns.each do |ssn|
      it "matches #{ssn}" do
        expect(ssn).to match(described_class::SSN_REGEX)
      end
    end
  end
end
