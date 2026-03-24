# frozen_string_literal: true

RSpec.describe TopSecret::Category do
  describe "method names" do
    it "derives method names from a simple type" do
      category = described_class.new(:email)

      expect(category.plural).to eq(:emails)
      expect(category.predicate).to eq(:emails?)
      expect(category.mapping_method).to eq(:email_mapping)
      expect(category.mapping_predicate).to eq(:email_mapping?)
    end

    it "derives method names from a compound type" do
      category = described_class.new(:credit_card)

      expect(category.plural).to eq(:credit_cards)
      expect(category.mapping_method).to eq(:credit_card_mapping)
    end

    it "resolves a mapping method" do
      category = described_class.new(:email)
      mapping = {EMAIL_1: "ralph@example.com", EMAIL_2: "ruby@example.com", PERSON_1: "Ralph"}

      expect(category.resolve(:email_mapping, mapping)).to eq({
        EMAIL_1: "ralph@example.com",
        EMAIL_2: "ruby@example.com"
      })
    end

    it "pluralizes the type before appending _mapping when the type already ends in _mapping" do
      category = described_class.new(:network_mapping)

      expect(category.plural).to eq(:network_mappings)
      expect(category.predicate).to eq(:network_mappings?)
      expect(category.mapping_method).to eq(:network_mappings_mapping)
      expect(category.mapping_predicate).to eq(:network_mappings_mapping?)
    end

    it "matches when the mapping contains keys for the category" do
      category = described_class.new(:email)

      expect(category.matches?({EMAIL_1: "ralph@example.com", PERSON_1: "Ralph"})).to be true
      expect(category.matches?({PERSON_1: "Ralph"})).to be false
    end

    it "raises when resolving an unrecognized method name" do
      category = described_class.new(:email)

      expect { category.resolve(:unknown, {}) }.to raise_error(ArgumentError)
    end
  end

  describe ".type_from_key" do
    it "extracts the label type from a key" do
      expect(described_class.type_from_key(:EMAIL_1)).to eq("EMAIL")
      expect(described_class.type_from_key(:CREDIT_CARD_2)).to eq("CREDIT_CARD")
    end
  end

  describe ".from" do
    it "builds categories from a mapping and filters" do
      mapping = {EMAIL_1: "ralph@example.com", PERSON_1: "Ralph"}
      filters = [
        TopSecret.email_filter,
        TopSecret.people_filter
      ].compact

      categories = described_class.from(mapping:, filters:)

      expect(categories.map(&:type)).to match_array(%w[email person])
    end
  end
end
