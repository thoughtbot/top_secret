# frozen_string_literal: true

module TopSecret
  class Error < StandardError
    class MalformedLabel < StandardError; end
  end
end
