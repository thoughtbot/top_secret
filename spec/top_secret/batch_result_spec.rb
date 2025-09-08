# frozen_string_literal: true

RSpec.describe TopSecret::Text::BatchResult do
  subject { described_class.new(mapping:, items: []) }

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
end
