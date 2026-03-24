# frozen_string_literal: true

module TopSecret
  class Text
    # Generates unique, sequenced label symbols for each label type.
    #
    # @example
    #   sequence = TopSecret::Text::LabelSequence.new
    #   sequence.next_label("EMAIL")       # => :EMAIL_1
    #   sequence.next_label("EMAIL")       # => :EMAIL_2
    #   sequence.next_label("PERSON")      # => :PERSON_1
    class LabelSequence
      # Creates a new LabelSequence instance with all counters at zero.
      def initialize
        @counters = Hash.new(0)
      end

      # Returns the next sequenced label for the given label type.
      #
      # @param label_type [String] the label type (e.g., "EMAIL", "CREDIT_CARD")
      # @return [Symbol] the sequenced label (e.g., :EMAIL_1, :EMAIL_2)
      def next_label(label_type)
        @counters[label_type] += 1
        :"#{label_type}#{TopSecret::LABEL_DELIMITER}#{@counters[label_type]}"
      end
    end
  end
end
