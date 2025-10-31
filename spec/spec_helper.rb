# frozen_string_literal: true

require "top_secret"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Clear the cached model before each test to ensure test isolation
  config.before(:each) do
    TopSecret::Text.clear_model_cache!
  end
end

def build_entity(text:, tag:, score: TopSecret.min_confidence_score)
  {text:, tag: tag.to_s.upcase, score:}
end

def stub_ner_entities(*entities)
  doc = instance_double("Mitie::Document", entities:)
  ner = instance_double("Mitie::NER", doc:)

  stub_const("Mitie::NER", class_double("Mitie::NER", new: ner))
end
