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
        NETWORK_MAPPING_1: "10.0.1.0/24 -> 192.168.1.0/24",
        PORT_MAPPING_RULE_1: "80:8080"
      }
    end

    it "categorizes by labels" do
      expect(subject.emails?).to be true
      expect(subject.people?).to be true
      expect(subject.credit_card_numbers?).to be true
      expect(subject.network_mappings?).to be true
      expect(subject.port_mapping_rules?).to be true

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
      expect(subject.port_mapping_rules).to eq([
        "80:8080"
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
      expect(subject.port_mapping_rule_mapping).to eq({
        PORT_MAPPING_RULE_1: "80:8080"
      })
    end

    it "only includes categories that have matches in the mapping" do
      expect(subject.categories).to match_array(
        [:email, :person, :ip_address, :credit_card_number, :network_mapping, :port_mapping_rule]
      )
    end

    context "when labels share a common prefix" do
      let(:mapping) do
        {
          EMAIL_1: "ralph@example.com",
          EMAIL_ADDRESS_1: "ruby@example.com"
        }
      end

      it "does not conflate labels with overlapping prefixes" do
        expect(subject.email_mapping).to eq({
          EMAIL_1: "ralph@example.com"
        })

        expect(subject.email_address_mapping).to eq({
          EMAIL_ADDRESS_1: "ruby@example.com"
        })
      end

      it "returns distinct values for each category" do
        expect(subject.emails).to eq(["ralph@example.com"])
        expect(subject.email_addresses).to eq(["ruby@example.com"])
      end
    end

    it "does not leak custom label methods across instances" do
      result_a = described_class.new("input", "output", {WIDGET_1: "sprocket"})
      result_b = described_class.new("input", "output", {EMAIL_1: "ralph@example.com"})

      result_a.widgets

      expect(result_b).not_to respond_to(:widgets)
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
      expect(subject).to respond_to(:port_mapping_rules)
      expect(subject).to respond_to(:port_mapping_rules?)
      expect(subject).to respond_to(:port_mapping_rule_mapping)
    end

    context "when a dynamic method does not exist" do
      it "does not respond" do
        expect(subject).not_to respond_to(:junk)
      end
    end
  end
end
