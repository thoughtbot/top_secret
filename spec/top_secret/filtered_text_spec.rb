# frozen_string_literal: true

RSpec.describe TopSecret::FilteredText do
  describe ".restore" do
    it "restores filtered text from a mapping" do
      person = "Ralph"
      mapping = {PERSON_1: person}
      llm_response = "Hello, [PERSON_1]!"

      result = TopSecret::FilteredText.restore(llm_response, mapping:)

      expect(result.output).to eq("Hello, #{person}!")
      expect(result.unrestored).to eq([])
      expect(result.restored).to eq(["[PERSON_1]"])
    end

    context "when a filter has multiple underscores" do
      it "restores filtered text from a mapping" do
        person = "Ralph"
        mapping = {PERSON_NAME_1: person}
        llm_response = "Hello, [PERSON_NAME_1]!"

        result = TopSecret::FilteredText.restore(llm_response, mapping:)

        expect(result.output).to eq("Hello, #{person}!")
        expect(result.unrestored).to eq([])
        expect(result.restored).to eq(["[PERSON_NAME_1]"])
      end
    end

    context "when a filter has multiple digits" do
      it "restores filtered text from a mapping" do
        person = "Ralph"
        mapping = {PERSON_NAME_1_1: person}
        llm_response = "Hello, [PERSON_NAME_1_1]!"

        result = TopSecret::FilteredText.restore(llm_response, mapping:)

        expect(result.output).to eq("Hello, #{person}!")
        expect(result.unrestored).to eq([])
        expect(result.restored).to eq(["[PERSON_NAME_1_1]"])
      end
    end

    context "when the filter does not have the same casing" do
      it "does not restore filtered text from a mapping" do
        person = "Ralph"
        mapping = {PERSON_1: person}
        llm_response = "Hello, [person_1]!"

        result = TopSecret::FilteredText.restore(llm_response, mapping:)

        expect(result.output).to eq(llm_response)
        expect(result.unrestored).to eq(["[person_1]"])
        expect(result.restored).to eq([])
      end
    end

    context "when there are no matches" do
      it "returns a list of filters that could not be restored" do
        mapping = {EMAIL_1: "ralph@example.com"}
        llm_response = "Hello, [PERSON_1]!"

        result = TopSecret::FilteredText.restore(llm_response, mapping:)

        expect(result.output).to eq(llm_response)
        expect(result.unrestored).to eq(["[PERSON_1]"])
        expect(result.restored).to eq([])
      end
    end

    context "when there are partial matches" do
      it "returns a list of filters that could not be restored" do
        email = "ralph@example.com"
        mapping = {EMAIL_1: email}
        llm_response = "Hello, [PERSON_1]! I'll email you at [EMAIL_1]."

        result = TopSecret::FilteredText.restore(llm_response, mapping:)

        expect(result.output).to eq("Hello, [PERSON_1]! I'll email you at #{email}.")
        expect(result.unrestored).to eq(["[PERSON_1]"])
        expect(result.restored).to eq(["[EMAIL_1]"])
      end
    end

    context "when the same filter appears multiple times" do
      it "does not duplicate filters in the restored list" do
        person = "Ralph"
        mapping = {PERSON_1: person}
        llm_response = "Hello, [PERSON_1]! Nice to meet you, [PERSON_1]."

        result = TopSecret::FilteredText.restore(llm_response, mapping:)

        expect(result.output).to eq("Hello, #{person}! Nice to meet you, #{person}.")
        expect(result.unrestored).to eq([])
        expect(result.restored).to eq(["[PERSON_1]"])
      end
    end
  end
end
