# frozen_string_literal: true

RSpec.describe TopSecret::Text::LabelSequence do
  describe "#next_label" do
    it "returns sequenced labels for a given label type" do
      sequence = described_class.new

      expect(sequence.next_label("EMAIL")).to eq(:EMAIL_1)
      expect(sequence.next_label("EMAIL")).to eq(:EMAIL_2)
      expect(sequence.next_label("PERSON")).to eq(:PERSON_1)
    end
  end
end
