# frozen_string_literal: true

RSpec.describe TopSecret do
  it "has a version number" do
    expect(TopSecret::VERSION).not_to be nil
  end

  it "has default configuration values" do
    expect(TopSecret.model_path).to eq("ner_model.dat")
    expect(TopSecret.min_confidence_score).to eq(0.5)
    expect(TopSecret.default_filters).to match(
      credit_card_filter: an_instance_of(TopSecret::Filters::Regex),
      email_filter: an_instance_of(TopSecret::Filters::Regex),
      phone_number_filter: an_instance_of(TopSecret::Filters::Regex),
      ssn_filter: an_instance_of(TopSecret::Filters::Regex),
      people_filter: an_instance_of(TopSecret::Filters::NER),
      location_filter: an_instance_of(TopSecret::Filters::NER)
    )
  end
end

RSpec.describe "TopSecret Configuration" do
  before do
    doc = instance_double("Mitie::Document", entities: [])
    ner = instance_double("Mitie::NER", doc:)
    allow(Mitie::NER).to receive(:new).and_return(ner)
  end

  it "initializes Mitie::NER with the default TopSecret.model_path value" do
    TopSecret::Text.filter("")

    expect(Mitie::NER).to have_received(:new).with(TopSecret.model_path)
  end

  it "allows TopSecret.min_confidence_score to be overridden" do
    original = TopSecret.min_confidence_score

    ralph = build_entity(text: "Ralph", tag: :person, score: 0.5)
    stub_ner_entities(ralph)

    TopSecret.configure do |config|
      config.min_confidence_score = 100
    end

    result = TopSecret::Text.filter("Ralph")

    expect(result.output).to eq("Ralph")
    expect(result.mapping).to eq({})
  ensure
    TopSecret.configure { _1.min_confidence_score = original }
  end

  context "when the TopSecret.model_path configuration is overridden" do
    it "initializes Mitie::NER with the custom value" do
      original = TopSecret.model_path
      TopSecret.configure do |config|
        config.model_path = "custom_path.dat"
      end

      TopSecret::Text.filter("")

      expect(Mitie::NER).to have_received(:new).with("custom_path.dat")
    ensure
      TopSecret.configure { _1.model_path = original }
    end
  end

  it "allows TopSecret.default_filters to be overridden" do
    original = TopSecret.default_filters.email_filter

    TopSecret.configure do |config|
      config.default_filters.email_filter = TopSecret::Filters::Regex.new(
        label: "email",
        regex: /user\[at\]example\.com/
      )
    end

    result = TopSecret::Text.filter("user[at]example.com")

    expect(result.output).to eq("[email_1]")
    expect(result.mapping).to eq({
      email_1: "user[at]example.com"
    })
  ensure
    TopSecret.configure { _1.default_filters.email_filter = original }
  end

  it "allows TopSecret.default_filters to be ignored" do
    original = TopSecret.default_filters.email_filter

    TopSecret.configure do |config|
      config.default_filters.email_filter = nil
    end

    result = TopSecret::Text.filter("user@example.com")

    expect(result.output).to eq("user@example.com")
    expect(result.mapping).to eq({})
  ensure
    TopSecret.configure { _1.default_filters.email_filter = original }
  end

  it "respects new Regex filters" do
    TopSecret.configure do |config|
      config.default_filters.passport = TopSecret::Filters::Regex.new(
        label: "PASSPORT",
        regex: /\b[A-Z0-9]{6,9}\b/i
      )
    end

    result = TopSecret::Text.filter("A123456")

    expect(result.output).to eq("[PASSPORT_1]")
    expect(result.mapping).to eq({
      PASSPORT_1: "A123456"
    })
  ensure
    TopSecret.configure { _1.default_filters.delete(:passport) }
  end

  it "respects new NER filters" do
    ip_address = build_entity(text: "192.168.1.1", tag: :ip_address)
    stub_ner_entities(ip_address)

    TopSecret.configure do |config|
      config.default_filters.passport = TopSecret::Filters::NER.new(
        label: "IP_ADDRESS",
        tag: :ip_address
      )
    end

    result = TopSecret::Text.filter("192.168.1.1")

    expect(result.output).to eq("[IP_ADDRESS_1]")
    expect(result.mapping).to eq({
      IP_ADDRESS_1: "192.168.1.1"
    })
  ensure
    TopSecret.configure { _1.default_filters.delete(:passport) }
  end
end
