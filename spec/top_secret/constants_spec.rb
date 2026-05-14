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

    it "captures the full #{phone_number} (no leading/trailing chars left behind)" do
      match = phone_number.match(TopSecret::PHONE_REGEX)

      expect(match[0]).to eq(phone_number)
    end
  end

  it "captures the leading paren when embedded in surrounding text" do
    input = "My phone number is (555) 555-5555"

    match = input.match(TopSecret::PHONE_REGEX)

    expect(match[0]).to eq("(555) 555-5555")
  end

  it "does not match a longer digit run" do
    expect("12345678901234").not_to match(TopSecret::PHONE_REGEX)
  end
end
