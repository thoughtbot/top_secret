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
        PERSON_1: "Ralph"
      }
    end

    it "categorizes by labels" do
      expect(subject.emails?).to be true
      expect(subject.people?).to be true

      expect(subject.emails).to eq([
        "ralph@example.com",
        "ruby@example.com"
      ])
      expect(subject.people).to eq([
        "Ralph"
      ])

      expect(subject.email_mapping).to eq({
        EMAIL_1: "ralph@example.com",
        EMAIL_2: "ruby@example.com"
      })
      expect(subject.person_mapping).to eq({
        PERSON_1: "Ralph"
      })
    end

    it "extracts types" do
      expect(subject.types).to eq([
        :email,
        :person
      ])
    end

    it "responds to dynamic methods" do
      expect(subject).to respond_to(:emails)
      expect(subject).to respond_to(:emails?)
      expect(subject).to respond_to(:email_mapping)
      expect(subject).to respond_to(:people)
      expect(subject).to respond_to(:people?)
      expect(subject).to respond_to(:person_mapping)
    end
  end
end
