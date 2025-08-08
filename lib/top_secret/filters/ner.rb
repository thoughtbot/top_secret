# frozen_string_literal: true

module TopSecret
  module Filters
    # Applies Named Entity Recognition (NER) filtering based on tag and confidence score.
    class NER
      # @return [String] The label applied to matching entities
      attr_reader :label

      # @param label [String] The label for redacted entities
      # @param tag [Symbol, String] The NER tag to match (e.g., :person, :location)
      # @param min_confidence_score [Float, nil] Minimum score required for a match (defaults to TopSecret.min_confidence_score)
      def initialize(label:, tag:, min_confidence_score: nil)
        @label = label
        @tag = tag.upcase.to_s
        @min_confidence_score = min_confidence_score
      end

      # Filters and extracts entity texts matching the tag and score threshold.
      #
      # @param entities [Array<Hash>] List of entity hashes with keys :tag, :score, and :text
      # @return [Array<String>] Matched entity texts
      def call(entities)
        tags = entities.filter { _1.fetch(:tag) == tag && _1.fetch(:score) >= (min_confidence_score || TopSecret.min_confidence_score) }
        tags.map { _1.fetch(:text) }
      end

      private

      # @return [String] The expected tag (uppercased)
      attr_reader :tag

      # @return [Float] Minimum confidence score for matches
      attr_reader :min_confidence_score
    end
  end
end
