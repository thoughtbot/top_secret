# frozen_string_literal: true

RSpec.describe TopSecret::Text::Result do
  subject { described_class.new("input", "output", mapping) }

  describe "#safe?" do
    context "when #mapping is empty" do
      let(:mapping) { {} }

      it "returns true" do
        expect(subject.safe?).to be true
      end
    end

    context "when #mapping has values" do
      let(:mapping) { {EMAIL_1: "ralph@example.com"} }

      it "returns false" do
        expect(subject.safe?).to be false
      end
    end
  end

  describe "#sensitive?" do
    context "when #mapping is empty" do
      let(:mapping) { {} }

      it "returns false" do
        expect(subject.sensitive?).to be false
      end
    end

    context "when #mapping has values" do
      let(:mapping) { {EMAIL_1: "ralph@example.com"} }

      it "returns true" do
        expect(subject.sensitive?).to be true
      end
    end
  end

  describe "categorization" do
    let(:mapping) do
      {
        EMAIL_1: "ralph@example.com",
        EMAIL_2: "ruby@example.com",
        PERSON_1: "Ralph",
        IP_ADDRESS_1: "192.168.1.1",
        CREDIT_CARD_NUMBER_1: "4242424242424242",
        NETWORK_MAPPING_1: "10.0.1.0/24 -> 192.168.1.0/24"
      }
    end

    it "categorizes by labels" do
      expect(subject.emails?).to be true
      expect(subject.people?).to be true
      expect(subject.credit_card_numbers?).to be true
      expect(subject.network_mappings?).to be true

      expect(subject.emails).to eq([
        "ralph@example.com",
        "ruby@example.com"
      ])
      expect(subject.people).to eq([
        "Ralph"
      ])
      expect(subject.credit_card_numbers).to eq([
        "4242424242424242"
      ])
      expect(subject.network_mappings).to eq([
        "10.0.1.0/24 -> 192.168.1.0/24"
      ])

      expect(subject.email_mapping).to eq({
        EMAIL_1: "ralph@example.com",
        EMAIL_2: "ruby@example.com"
      })
      expect(subject.person_mapping).to eq({
        PERSON_1: "Ralph"
      })
      expect(subject.credit_card_number_mapping).to eq({
        CREDIT_CARD_NUMBER_1: "4242424242424242"
      })
      expect(subject.network_mappings_mapping).to eq({
        NETWORK_MAPPING_1: "10.0.1.0/24 -> 192.168.1.0/24"
      })
    end

    it "extracts types" do
      expect(subject.types).to include(
        :email,
        :person,
        :ip_address,
        :credit_card_number,
        :network_mapping,
        :credit_card,
        :phone_number,
        :ssn,
        :location
      )
    end

    it "responds to dynamic methods" do
      expect(subject).to respond_to(:emails)
      expect(subject).to respond_to(:emails?)
      expect(subject).to respond_to(:email_mapping)
      expect(subject).to respond_to(:people)
      expect(subject).to respond_to(:people?)
      expect(subject).to respond_to(:person_mapping)
      expect(subject).to respond_to(:credit_card_numbers)
      expect(subject).to respond_to(:credit_card_numbers?)
      expect(subject).to respond_to(:credit_card_number_mapping)
      expect(subject).to respond_to(:network_mappings)
      expect(subject).to respond_to(:network_mappings_mapping?)
      expect(subject).to respond_to(:network_mappings_mapping)
    end
  end
end
