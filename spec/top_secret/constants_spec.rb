# frozen_string_literal: true

RSpec.describe "TopSecret::PHONE_REGEX" do
  describe "common formats" do
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

  it "matches embedded parenthesized number and preserves mapping" do
    input  = "My phone number is (555) 555-5555"
    output = input.gsub(TopSecret::PHONE_REGEX) { "[PHONE_NUMBER_1]" }
    md     = input.match(TopSecret::PHONE_REGEX)

    expect(output).to eq("My phone number is [PHONE_NUMBER_1]")
    expect(md[0]).to eq("(555) 555-5555")
  end
end
