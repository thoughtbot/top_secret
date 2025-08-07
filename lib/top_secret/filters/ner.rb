# frozen_string_literal: true

module TopSecret
  module Filters
    class NER
      attr_reader :label

      def initialize(label:, tag:, min_confidence_score: nil)
        @label = label
        @tag = tag.upcase.to_s
        @min_confidence_score = min_confidence_score || TopSecret.min_confidence_score
      end

      def call(entities)
        tags = entities.filter { _1.fetch(:tag) == tag && _1.fetch(:score) >= min_confidence_score }
        tags.map { _1.fetch(:text) }
      end

      private

      attr_reader :tag, :min_confidence_score
    end
  end
end
