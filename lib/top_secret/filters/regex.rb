# frozen_string_literal: true

module TopSecret
  module Filters
    class Regex
      attr_reader :label

      def initialize(label:, regex:)
        @label = label
        @regex = regex
      end

      def call(input)
        input.scan(regex)
      end

      private

      attr_reader :regex
    end
  end
end
