# frozen_string_literal: true

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
