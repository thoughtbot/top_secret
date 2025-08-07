# frozen_string_literal: true

module TopSecret
  class Result
    attr_reader :input, :output, :mapping

    def initialize(input, output, mapping)
      @input = input
      @output = output
      @mapping = mapping
    end
  end
end
