# frozen_string_literal: true

require_relative "lib/top_secret/version"

Gem::Specification.new do |spec|
  spec.name = "top_secret"
  spec.version = TopSecret::VERSION
  spec.authors = ["Steve Polito"]
  spec.email = ["stevepolito@hey.com"]

  spec.summary = "Filter sensitive information from free text."
  spec.description = "Filter sensitive information from free text before sending it to external services or APIs, such as Chatbots."
  spec.homepage = "https://github.com/thoughtbot/top_secret"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/thoughtbot/top_secret/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .standard.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "~> 8.0", ">= 8.0.2"
  spec.add_dependency "mitie", "~> 0.3.2"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
