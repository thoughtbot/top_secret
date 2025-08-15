# Top Secret

[![Ruby](https://github.com/thoughtbot/top_secret/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/thoughtbot/top_secret/actions/workflows/main.yml)

Filter sensitive information from free text before sending it to external services or APIs, such as chatbots and LLMs.

By default it filters the following:

-   Credit cards
-   Emails
-   Phone numbers
-   Social security numbers
-   People's names
-   Locations

However, you can add your own [custom filters](#custom-filters).

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add top_secret
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install top_secret
```

> [!IMPORTANT]
> Top Secret depends on [MITIE Ruby][], which depends on [MITIE][].
>
> You'll need to download and extract [ner_model.dat][] first.

By default, Top Secret assumes the file will live at the root of your project, but this can be configured.

```ruby
TopSecret.configure do |config|
  config.model_path = "path/to/ner_model.dat"
end
```

## Default Filters

Top Secret ships with a set of filters to detect and redact the most common types of sensitive information.

You can [override](#overriding-the-default-filters-1), [disable](#disabling-a-default-filter-1), or [add](#adding-new-default-filters) to this list as needed.

By default, the following filters are enabled

**`credit_card_filter`**

Matches common credit card formats

```ruby
result = TopSecret::Text.filter("My card number is 4242-4242-4242-4242")
result.output

# => "My card number is [CREDIT_CARD_1]"
```

**`email_filter`**

Matches email addresses

```ruby
result = TopSecret::Text.filter("Email me at ralph@thoughtbot.com")
result.output

# => "Email me at [EMAIL_1]"
```

**`phone_number_filter`**

Matches phone numbers

```ruby
result = TopSecret::Text.filter("Call me at 555-555-5555")
result.output

# => "Call me at [PHONE_NUMBER_1]"
```

**`ssn_filter`**

Matches U.S. Social Security numbers

```ruby
result = TopSecret::Text.filter("My SSN is 123-45-6789")
result.output

# => "My SSN is [SSN_1]"
```

**`people_filter`**

Detects names of people (NER-based)

```ruby
result = TopSecret::Text.filter("Ralph is joining the meeting")
result.output

# => "[PERSON_1] is joining the meeting"
```

**`location_filter`**

Detects location names (NER-based)

```ruby
result = TopSecret::Text.filter("Let's meet in Boston")
result.output

# => "Let's meet in [LOCATION_1]"
```

## Usage

```ruby
TopSecret::Text.filter("Ralph can be reached at ralph@thoughtbot.com")
```

This will return

```ruby
<TopSecret::Result
  @input="Ralph can be reached at ralph@thoughtbot.com",
  @mapping={:EMAIL_1=>"ralph@thoughtbot.com", :PERSON_1=>"Ralph"},
  @output="[PERSON_1] can be reached at [EMAIL_1]"
>
```

View the original text

```ruby
result.input

# => "Ralph can be reached at ralph@thoughtbot.com"
```

View the filtered text

```ruby
result.output

# => "[PERSON_1] can be reached at [EMAIL_1]"
```

View the mapping

```ruby
result.mapping

# => {:EMAIL_1=>"ralph@thoughtbot.com", :PERSON_1=>"Ralph"}
```

### Advanced Examples

#### Overriding the default filters

When overriding or [disabling](#disabling-a-default-filter-1) a [default filter](#default-filters), you must map to the correct key.

> [!IMPORTANT]
> Invalid filter keys will raise an `ArgumentError`. Only the following keys are valid:
> `credit_card_filter`, `email_filter`, `phone_number_filter`, `ssn_filter`, `people_filter`, `location_filter`

```ruby
regex_filter = TopSecret::Filters::Regex.new(label: "EMAIL_ADDRESS", regex: /\b\w+\[at\]\w+\.\w+\b/)
ner_filter = TopSecret::Filters::NER.new(label: "NAME", tag: :person, min_confidence_score: 0.25)

TopSecret::Text.filter("Ralph can be reached at ralph[at]thoughtbot.com",
  email_filter: regex_filter,
  people_filter: ner_filter
)
```

This will return

```ruby
<TopSecret::Result
  @input="Ralph can be reached at ralph[at]thoughtbot.com",
  @mapping={:EMAIL_ADDRESS_1=>"ralph[at]thoughtbot.com", :NAME_1=>"Ralph", :NAME_2=>"ralph["},
  @output="[NAME_1] can be reached at [EMAIL_ADDRESS_1]"
>
```

#### Disabling a default filter

```ruby
TopSecret::Text.filter("Ralph can be reached at ralph@thoughtbot.com",
  email_filter: nil,
  people_filter: nil
)
```

This will return

```ruby
<TopSecret::Result
  @input="Ralph can be reached at ralph@thoughtbot.com",
  @mapping={},
  @output="Ralph can be reached at ralph@thoughtbot.com"
>
```

#### Error handling for invalid filter keys

```ruby
# This will raise ArgumentError: Unknown key: :invalid_filter. Valid keys are: ...
TopSecret::Text.filter("some text", invalid_filter: some_filter)
```

### Custom Filters

#### Adding new [Regex filters][]

```ruby
ip_address_filter = TopSecret::Filters::Regex.new(
  label: "IP_ADDRESS",
  regex: /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/
)

TopSecret::Text.filter("Ralph's IP address is 192.168.1.1",
  custom_filters: [ip_address_filter]
)
```

This will return

```ruby
<TopSecret::Result
  @input="Ralph's IP address is 192.168.1.1",
  @mapping={:PERSON_1=>"Ralph", :IP_ADDRESS_1=>"192.168.1.1"},
  @output="[PERSON_1]'s IP address is [IP_ADDRESS_1]"
>
```

#### Adding new [NER filters][]

Since [MITIE Ruby][] has an API for [training][train] a model, you're free to add new NER filters.

```ruby
language_filter = TopSecret::Filters::NER.new(
  label: "LANGUAGE",
  tag: :language,
  min_confidence_score: 0.75
)

TopSecret::Text.filter("Ralph's favorite programming language is Ruby.",
  custom_filters: [language_filter]
)
```

This will return

```ruby
<TopSecret::Result
  @input="Ralph's favorite programming language is Ruby.",
  @mapping={:PERSON_1=>"Ralph", :LANGUAGE_1=>"Ruby"},
  @output="[PERSON_1]'s favorite programming language is [LANGUAGE_1]"
>
```

## How Filters Work

Top Secret uses two types of filters to detect and redact sensitive information:

### `TopSecret::Filters::Regex`

`Regex` filters use regular expressions to find patterns in text.
They are useful for structured data like credit card numbers, emails, or IP addresses.

```ruby
regex_filter = TopSecret::Filters::Regex.new(
  label: "IP_ADDRESS",
  regex: /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/
)

result = TopSecret::Text.filter("Server IP: 192.168.1.1",
  custom_filters: [regex_filter]
)

result.output
# => "Server IP: [IP_ADDRESS_1]"
```

### `TopSecret::Filters::NER`

`NER` (Named Entity Recognition) filters use the [MITIE][] library to detect entities like people, locations, and other categories based on trained language models.
They are ideal for free-form text where patterns are less predictable.

```ruby
ner_filter = TopSecret::Filters::NER.new(
  label: "PERSON",
  tag: :person,
  min_confidence_score: 0.25
)

result = TopSecret::Text.filter("Ralph and Ruby work at thoughtbot.",
  people_filter: ner_filter
)

result.output
# => "[PERSON_1] and [PERSON_2] work at thoughtbot."
```

`NER` filters match based on the tag you specify (`:person`, `:location`, etc.) and only include matches with a confidence score above `min_confidence_score`.

#### Supported NER Tags

By default, Top Secret only ships with `NER` filters for two entity types:

-   `:person`
-   `:location`

If you need other tags you can [train your own MITIE model][train] and add custom NER filters:

## Configuration

### Overriding the model path

```ruby
TopSecret.configure do |config|
  config.model_path = "path/to/ner_model.dat"
end
```

### Overriding the confidence score

```ruby
TopSecret.configure do |config|
  config.min_confidence_score = 0.75
end
```

### Overriding the default filters

```ruby
TopSecret.configure do |config|
  config.email_filter = TopSecret::Filters::Regex.new(
    label: "EMAIL_ADDRESS",
    regex: /\b\w+\[at\]\w+\.\w+\b/
  )
end
```

### Disabling a default filter

```ruby
TopSecret.configure do |config|
  config.email_filter = nil
end
```

### Adding custom filters globally

```ruby
ip_address_filter = TopSecret::Filters::Regex.new(
  label: "IP_ADDRESS",
  regex: /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/
)

TopSecret.configure do |config|
  config.custom_filters << ip_address_filter
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

> [!IMPORTANT]
> Top Secret depends on [MITIE Ruby][], which depends on [MITIE][].
>
> You'll need to download and extract [ner_model.dat][] first, and place it in the root of this project.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

[Bug reports](https://github.com/thoughtbot/top_secret/issues/new?template=bug_report.md) and [pull requests](https://github.com/thoughtbot/top_secret/pulls) are welcome on GitHub at [https://github.com/thoughtbot/top_secret](https://github.com/thoughtbot/top_secret).

Please create a [new discussion](https://github.com/thoughtbot/top_secret/discussions/new?category=ideas) if you want to share ideas for new features.

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/thoughtbot/top_secret/blob/main/CODE_OF_CONDUCT.md).

## License

Open source templates are Copyright (c) thoughtbot, inc.
It contains free software that may be redistributed under the terms specified in the [LICENSE](https://github.com/thoughtbot/top_secret/blob/main/LICENSE.txt) file.

## Code of Conduct

Everyone interacting in the TopSecret project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/thoughtbot/top_secret/blob/main/CODE_OF_CONDUCT.md).

<!-- START /templates/footer.md -->

## About thoughtbot

![thoughtbot](https://thoughtbot.com/thoughtbot-logo-for-readmes.svg)

This repo is maintained and funded by thoughtbot, inc.
The names and logos for thoughtbot are trademarks of thoughtbot, inc.

We love open source software!
See [our other projects][community].
We are [available for hire][hire].

[community]: https://thoughtbot.com/community?utm_source=github
[hire]: https://thoughtbot.com/hire-us?utm_source=github

<!-- END /templates/footer.md -->

[MITIE Ruby]: https://github.com/ankane/mitie-ruby
[MITIE]: https://github.com/mit-nlp/MITIE
[ner_model.dat]: https://github.com/mit-nlp/MITIE/releases/download/v0.4/MITIE-models-v0.2.tar.bz2
[train]: https://github.com/ankane/mitie-ruby?tab=readme-ov-file#training
[Regex filters]: https://github.com/thoughtbot/top_secret/blob/main/lib/top_secret/filters/regex.rb
[NER filters]: https://github.com/thoughtbot/top_secret/blob/main/lib/top_secret/filters/ner.rb
