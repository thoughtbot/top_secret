# frozen_string_literal: true

RSpec.describe TopSecret do
  it "has a version number" do
    expect(TopSecret::VERSION).not_to be nil
  end
end

RSpec.describe "TopSecret::PHONE_REGEX" do
  phone_numbers = [
    "+1 415-555-1234",
    "(415) 555-1234",
    "415.555.1234",
    "415 555 1234",
    "415-555-1234"
  ]

  phone_numbers.each do |phone_number|
    it "matches #{phone_number}" do
      expect(phone_number).to match(TopSecret::PHONE_REGEX)
    end
  end
end

RSpec.describe TopSecret::Text do
  describe ".filter" do
    it "filters sensitive information from free text and creates a mapping" do
      input = <<~TEXT
        My email address is user@example.com
        My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
        My social security number is 123-45-6789
        My phone number is 555-555-5555
      TEXT

      result = TopSecret::Text.filter(input)

      expect(result.output).to eq(<<~TEXT)
        My email address is [EMAIL_1]
        My credit card numbers are [CREDIT_CARD_1] and [CREDIT_CARD_2]
        My social security number is [SSN_1]
        My phone number is [PHONE_NUMBER_1]
      TEXT
      expect(result.mapping).to eq({
        EMAIL_1: "user@example.com",
        CREDIT_CARD_1: "4242-4242-4242-4242",
        CREDIT_CARD_2: "4141414141414141",
        SSN_1: "123-45-6789",
        PHONE_NUMBER_1: "555-555-5555"
      })
      expect(result.input).to eq(input)
    end

    it "removes duplicate entries from the mapping" do
      result = TopSecret::Text.filter("user@example.com user@example.com")

      expect(result.mapping).to eq({
        EMAIL_1: "user@example.com"
      })
    end

    it "filters email addresses from free text" do
      result = TopSecret::Text.filter("user@example.com")

      expect(result.output).to eq("[EMAIL_1]")
    end

    it "filters delimited credit card numbers from free text" do
      result = TopSecret::Text.filter("4242-4242-4242-4242")

      expect(result.output).to eq("[CREDIT_CARD_1]")
    end

    it "filters non-delimited credit card numbers from free text" do
      result = TopSecret::Text.filter("4242424242424242")

      expect(result.output).to eq("[CREDIT_CARD_1]")
    end

    it "filters social security numbers from free text" do
      result = TopSecret::Text.filter("123-45-6789")

      expect(result.output).to eq("[SSN_1]")
    end

    it "filters phone numbers from free text" do
      result = TopSecret::Text.filter("555-555-5555")

      expect(result.output).to eq("[PHONE_NUMBER_1]")
    end

    it "returns a TopSecret::Result" do
      result = TopSecret::Text.filter("")

      expect(result).to be_an_instance_of(TopSecret::Result)
    end

    context "when there are multiple unique email addresses" do
      it "filters each email address from free text" do
        result = TopSecret::Text.filter("user_1@example.com user_2@example.com")

        expect(result.output).to eq("[EMAIL_1] [EMAIL_2]")
      end
    end

    context "when there are multiple identical email addresses" do
      it "filters each email address from free text, and maps them to the same filter" do
        result = TopSecret::Text.filter("user_1@example.com user_1@example.com")

        expect(result.output).to eq("[EMAIL_1] [EMAIL_1]")
      end
    end

    context "when there are multiple unique credit card numbers" do
      it "filters each credit card number from free text" do
        input = <<~TEXT
          4242-4242-4242-4242
          4141-4141-4141-4141
          4242424242424242
          4141414141414141
        TEXT

        result = TopSecret::Text.filter(input)

        expect(result.output).to eq(<<~TEXT)
          [CREDIT_CARD_1]
          [CREDIT_CARD_2]
          [CREDIT_CARD_3]
          [CREDIT_CARD_4]
        TEXT
      end
    end

    context "when there are multiple identical credit card numbers" do
      it "filters each credit card number from free text, and maps to the same filter" do
        input = <<~TEXT
          4242-4242-4242-4242
          4242-4242-4242-4242
          4141-4141-4141-4141
          4141-4141-4141-4141
          4242424242424242
          4242424242424242
          4141414141414141
          4141414141414141
        TEXT

        result = TopSecret::Text.filter(input)

        expect(result.output).to eq(<<~TEXT)
          [CREDIT_CARD_1]
          [CREDIT_CARD_1]
          [CREDIT_CARD_2]
          [CREDIT_CARD_2]
          [CREDIT_CARD_3]
          [CREDIT_CARD_3]
          [CREDIT_CARD_4]
          [CREDIT_CARD_4]
        TEXT
      end
    end

    context "when there are multiple unique social security numbers" do
      it "filters each social security number from free text" do
        result = TopSecret::Text.filter("123-45-6789 000-00-0000")

        expect(result.output).to eq("[SSN_1] [SSN_2]")
      end
    end

    context "when there are multiple identical social security numbers" do
      it "filters each social security number from free text, and maps them to the same filter" do
        result = TopSecret::Text.filter("123-45-6789 123-45-6789")

        expect(result.output).to eq("[SSN_1] [SSN_1]")
      end
    end

    context "when there are multiple unique phone numbers" do
      it "filters each phone number from free text" do
        result = TopSecret::Text.filter("555-555-5555 444-444-4444")

        expect(result.output).to eq("[PHONE_NUMBER_1] [PHONE_NUMBER_2]")
      end
    end

    context "when there are multiple identical phone numbers" do
      it "filters each phone number from free text, and maps them to the same filter" do
        result = TopSecret::Text.filter("555-555-5555 555-555-5555")

        expect(result.output).to eq("[PHONE_NUMBER_1] [PHONE_NUMBER_1]")
      end
    end
  end
end
