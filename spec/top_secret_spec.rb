# frozen_string_literal: true

RSpec.describe TopSecret do
  it "has a version number" do
    expect(TopSecret::VERSION).not_to be nil
  end
end

RSpec.describe TopSecret::Text do
  describe ".filter" do
    it "filters sensitive information from free text" do
      input = <<~TEXT
        My email address is user@example.com
      TEXT

      result = TopSecret::Text.filter(input)

      expect(result.output).to eq(<<~TEXT)
        My email address is [EMAIL_1]
      TEXT
      expect(result.input).to eq(input)
    end

    it "filters email addresses from free text" do
      result = TopSecret::Text.filter("user@example.com")

      expect(result.output).to eq("[EMAIL_1]")
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
  end
end
