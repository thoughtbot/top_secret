# frozen_string_literal: true

module TopSecret
  # A null object implementation that provides a no-op interface compatible with Mitie::NER.
  # Used when NER filtering is disabled (model_path is nil) to eliminate conditional checks
  # throughout the codebase.
  #
  # @example
  #   model = TopSecret::NullModel.new
  #   doc = model.doc("some text")
  #   doc.entities # => []
  class NullModel
    # A null document implementation that provides an empty entities array.
    # Used as the return value from NullModel#doc to maintain interface compatibility.
    class NullDoc
      # Returns an empty array of entities.
      #
      # @return [Array] Always returns an empty array
      def entities
        []
      end
    end

    # Creates a null document that returns empty entities.
    #
    # @param input [String] The input text (ignored)
    # @return [NullDoc] A document-like object with empty entities
    def doc(input)
      NullDoc.new
    end
  end
end
