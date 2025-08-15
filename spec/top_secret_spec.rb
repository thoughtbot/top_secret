# frozen_string_literal: true

RSpec.describe TopSecret do
  it "has a version number" do
    expect(TopSecret::VERSION).not_to be nil
  end

  it "has default configuration values" do
    expect(TopSecret.model_path).to eq("ner_model.dat")
    expect(TopSecret.min_confidence_score).to eq(0.5)
    expect(TopSecret.credit_card_filter).to be_an_instance_of(TopSecret::Filters::Regex)
    expect(TopSecret.email_filter).to be_an_instance_of(TopSecret::Filters::Regex)
    expect(TopSecret.phone_number_filter).to be_an_instance_of(TopSecret::Filters::Regex)
    expect(TopSecret.ssn_filter).to be_an_instance_of(TopSecret::Filters::Regex)
    expect(TopSecret.people_filter).to be_an_instance_of(TopSecret::Filters::NER)
    expect(TopSecret.location_filter).to be_an_instance_of(TopSecret::Filters::NER)
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

  it "allows email filter to be overridden" do
    original = TopSecret.email_filter

    TopSecret.configure do |config|
      config.email_filter = TopSecret::Filters::Regex.new(
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
    TopSecret.configure { _1.email_filter = original }
  end

  it "allows email filter to be disabled" do
    original = TopSecret.email_filter

    TopSecret.configure do |config|
      config.email_filter = nil
    end

    result = TopSecret::Text.filter("user@example.com")

    expect(result.output).to eq("user@example.com")
    expect(result.mapping).to eq({})
  ensure
    TopSecret.configure { _1.email_filter = original }
  end

  it "respects custom Regex filters" do
    passport_filter = TopSecret::Filters::Regex.new(
      label: "PASSPORT",
      regex: /\b[A-Z0-9]{6,9}\b/i
    )

    result = TopSecret::Text.filter("A123456", custom_filters: [passport_filter])

    expect(result.output).to eq("[PASSPORT_1]")
    expect(result.mapping).to eq({
      PASSPORT_1: "A123456"
    })
  end

  it "respects custom NER filters" do
    ip_address = build_entity(text: "192.168.1.1", tag: :ip_address)
    stub_ner_entities(ip_address)

    ip_filter = TopSecret::Filters::NER.new(
      label: "IP_ADDRESS",
      tag: :ip_address
    )

    result = TopSecret::Text.filter("192.168.1.1", custom_filters: [ip_filter])

    expect(result.output).to eq("[IP_ADDRESS_1]")
    expect(result.mapping).to eq({
      IP_ADDRESS_1: "192.168.1.1"
    })
  end
end
