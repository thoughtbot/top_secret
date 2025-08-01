# TopSecret

Filter sensitive information from free text before sending it to external
services or APIs, such as Chatbots.

```ruby
input = <<~TEXT
  My email address is user@example.com
  My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
  My social security number is 123-45-6789
  My phone number is 555-555-5555
TEXT

result = TopSecret::Text.filter(input)
=> #<TopSecret::Result>

result.output
=> "My email address is [EMAIL_1]\n" \
   "My credit card numbers are [CREDIT_CARD_1] and [CREDIT_CARD_2]\n" \
   "My social security number is [SSN_1]\n" \
   "My phone number is [PHONE_NUMBER_1]\n"

result.mapping
=> {
  CREDIT_CARD_1: "4242-4242-4242-4242",
  CREDIT_CARD_2: "4141414141414141",
  EMAIL_1: "user@example.com",
  PHONE_NUMBER_1: "555-555-5555",
  SSN_1: "123-45-6789"
}
```

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/top_secret. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/top_secret/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TopSecret project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/top_secret/blob/main/CODE_OF_CONDUCT.md).
