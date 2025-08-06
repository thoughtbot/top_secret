# frozen_string_literal: true

RSpec.describe TopSecret do
  it "has a version number" do
    expect(TopSecret::VERSION).not_to be nil
  end

  it "is configurable" do
    expect(TopSecret.model_path).to eq("ner_model.dat")
    expect(TopSecret.min_confidence_score).to eq(0.5)
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
    before do
      ralph = build_entity(text: "Ralph", tag: :person)
      boston = build_entity(text: "Boston", tag: :location)
      stub_ner_entities(ralph, boston)
    end

    it "filters sensitive information from free text and creates a mapping" do
      input = <<~TEXT
        My name is Ralph
        My location is Boston
        My email address is user@example.com
        My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
        My social security number is 123-45-6789
        My phone number is 555-555-5555
      TEXT

      result = TopSecret::Text.filter(input)

      expect(result.output).to eq(<<~TEXT)
        My name is [PERSON_1]
        My location is [LOCATION_1]
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
        PHONE_NUMBER_1: "555-555-5555",
        PERSON_1: "Ralph",
        LOCATION_1: "Boston"
      })
      expect(result.input).to eq(input)
    end

    it "removes duplicate entries from the mapping" do
      result = TopSecret::Text.filter("user@example.com user@example.com")

      expect(result.mapping.fetch(:EMAIL_1)).to eq("user@example.com")
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

    it "filters names from free text" do
      result = TopSecret::Text.filter("Ralph")

      expect(result.output).to eq("[PERSON_1]")
    end

    it "filters locations from free text" do
      result = TopSecret::Text.filter("Boston")

      expect(result.output).to eq("[LOCATION_1]")
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

    context "when there are multiple unique people" do
      before do
        ralph = build_entity(text: "Ralph", tag: :person)
        ruby = build_entity(text: "Ruby", tag: :person)
        stub_ner_entities(ralph, ruby)
      end

      it "filters each person from free text" do
        result = TopSecret::Text.filter("Ralph Ruby")

        expect(result.output).to eq("[PERSON_1] [PERSON_2]")
      end
    end

    context "when there are multiple identical people" do
      before do
        ralph_1 = build_entity(text: "Ralph", tag: :person)
        ralph_2 = build_entity(text: "Ralph", tag: :person)
        stub_ner_entities(ralph_1, ralph_2)
      end

      it "filters each person from free text, and maps them to the same filter" do
        result = TopSecret::Text.filter("Ralph Ralph")

        expect(result.output).to eq("[PERSON_1] [PERSON_1]")
      end
    end

    context "when the confidence score is below the threshold for a person" do
      before do
        score = TopSecret.min_confidence_score - 0.1
        ralph = build_entity(text: "Ralph", tag: :person, score:)
        stub_ner_entities(ralph)
      end

      it "does not filter the person from free text" do
        result = TopSecret::Text.filter("Ralph")

        expect(result.output).to eq("Ralph")
      end
    end

    context "when there are multiple unique locations" do
      before do
        boston = build_entity(text: "Boston", tag: :location)
        new_york = build_entity(text: "New York", tag: :location)
        stub_ner_entities(boston, new_york)
      end

      it "filters each location from free text" do
        result = TopSecret::Text.filter("Boston New York")

        expect(result.output).to eq("[LOCATION_1] [LOCATION_2]")
      end
    end

    context "when there are multiple identical locations" do
      before do
        boston_1 = build_entity(text: "Boston", tag: :location)
        boston_2 = build_entity(text: "Boston", tag: :location)
        stub_ner_entities(boston_1, boston_2)
      end

      it "filters each location from free text, and maps them to the same filter" do
        result = TopSecret::Text.filter("Boston Boston")

        expect(result.output).to eq("[LOCATION_1] [LOCATION_1]")
      end
    end

    context "when the confidence score is below the threshold for a location" do
      before do
        score = TopSecret.min_confidence_score - 0.1
        boston = build_entity(text: "Boston", tag: :location, score:)
        stub_ner_entities(boston)
      end

      it "does not filter the location from free text" do
        result = TopSecret::Text.filter("Boston")

        expect(result.output).to eq("Boston")
      end
    end

    context "when the confidence score is passed as an option" do
      before do
        ralph = build_entity(text: "Ralph", tag: :person, score: 0.25)
        boston = build_entity(text: "Boston", tag: :location, score: 0.25)
        stub_ner_entities(ralph, boston)
      end

      it "uses that score to filter people and locations" do
        result = TopSecret::Text.filter("Ralph Boston", min_confidence_score: 0.25)

        expect(result.output).to eq("[PERSON_1] [LOCATION_1]")
      end
    end
  end

  describe "model_path configuration" do
    before do
      doc = instance_double("Mitie::Document", entities: [])
      ner = instance_double("Mitie::NER", doc:)
      allow(Mitie::NER).to receive(:new).and_return(ner)
    end

    it "initializes Mitie::NER with the default model_path" do
      TopSecret::Text.filter("")

      expect(Mitie::NER).to have_received(:new).with(TopSecret.model_path)
    end

    context "when the model_path is configured" do
      it "initializes Mitie::NER with model_path" do
        TopSecret.configure do |config|
          config.model_path = "custom_path.dat"
        end

        TopSecret::Text.filter("")

        expect(Mitie::NER).to have_received(:new).with("custom_path.dat")
      end
    end

    context "when the model_path is overridden" do
      it "initializes Mitie::NER with model_path" do
        TopSecret::Text.filter("", model_path: "custom_path.dat")

        expect(Mitie::NER).to have_received(:new).with("custom_path.dat")
      end
    end
  end

  private

  def build_entity(text:, tag:, score: TopSecret.min_confidence_score)
    {text:, tag: tag.to_s.upcase, score:}
  end

  def stub_ner_entities(*entities)
    doc = instance_double("Mitie::Document", entities:)
    ner = instance_double("Mitie::NER", doc:)

    stub_const("Mitie::NER", class_double("Mitie::NER", new: ner))
  end
end
