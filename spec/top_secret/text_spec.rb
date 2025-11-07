# frozen_string_literal: true

RSpec.describe TopSecret::Text do
  describe ".filter" do
    let(:ralph) { build_entity(text: "Ralph", tag: :person) }
    let(:boston) { build_entity(text: "Boston", tag: :location) }

    before do
      stub_ner_entities(ralph, boston)
    end

    it "filters sensitive information from free text and creates a mapping" do
      input = <<~TEXT
        My name is Ralph
        My location is Boston
        My email address is user@example.com
        My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
        My social security number is 123-45-6789
        My phone number is 555-555-5555
      TEXT

      result = TopSecret::Text.filter(input)

      expect(result.output).to eq(<<~TEXT)
        My name is [PERSON_1]
        My location is [LOCATION_1]
        My email address is [EMAIL_1]
        My credit card numbers are [CREDIT_CARD_1] and [CREDIT_CARD_2]
        My social security number is [SSN_1]
        My phone number is [PHONE_NUMBER_1]
      TEXT
      expect(result.mapping).to eq({
        EMAIL_1: "user@example.com",
        CREDIT_CARD_1: "4242-4242-4242-4242",
        CREDIT_CARD_2: "4141414141414141",
        SSN_1: "123-45-6789",
        PHONE_NUMBER_1: "555-555-5555",
        PERSON_1: "Ralph",
        LOCATION_1: "Boston"
      })
      expect(result.input).to eq(input)
      expect(result.sensitive?).to eq(true)
      expect(result.safe?).to eq(false)
    end

    it "categorizes sensitive information from free text" do
      input = <<~TEXT
        My name is Ralph
        My location is Boston
        My email address is user@example.com
        My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
        My social security number is 123-45-6789
        My phone number is 555-555-5555
      TEXT

      result = TopSecret::Text.filter(input)

      expect(result.emails).to eq(["user@example.com"])
      expect(result.emails?).to eq(true)
      expect(result.email_mapping).to eq({EMAIL_1: "user@example.com"})

      expect(result.people).to eq(["Ralph"])
      expect(result.people?).to eq(true)
      expect(result.person_mapping).to eq({PERSON_1: "Ralph"})

      expect(result.locations).to eq(["Boston"])
      expect(result.locations?).to eq(true)
      expect(result.location_mapping).to eq({LOCATION_1: "Boston"})

      expect(result.credit_cards).to eq(["4242-4242-4242-4242", "4141414141414141"])
      expect(result.credit_cards?).to eq(true)
      expect(result.credit_card_mapping).to eq({
        CREDIT_CARD_1: "4242-4242-4242-4242",
        CREDIT_CARD_2: "4141414141414141"
      })

      expect(result.ssns).to eq(["123-45-6789"])
      expect(result.ssns?).to eq(true)
      expect(result.ssn_mapping).to eq({SSN_1: "123-45-6789"})

      expect(result.phone_numbers).to eq(["555-555-5555"])
      expect(result.phone_numbers?).to eq(true)
      expect(result.phone_number_mapping).to eq({PHONE_NUMBER_1: "555-555-5555"})
    end

    context "when there is no sensitive information" do
      before do
        stub_ner_entities
      end

      it "categorizes sensitive information from free text" do
        result = TopSecret::Text.filter("")

        expect(result.emails).to eq([])
        expect(result.emails?).to eq(false)
        expect(result.email_mapping).to eq({})

        expect(result.people).to eq([])
        expect(result.people?).to eq(false)
        expect(result.person_mapping).to eq({})

        expect(result.locations).to eq([])
        expect(result.locations?).to eq(false)
        expect(result.location_mapping).to eq({})

        expect(result.credit_cards).to eq([])
        expect(result.credit_cards?).to eq(false)
        expect(result.credit_card_mapping).to eq({})

        expect(result.ssns).to eq([])
        expect(result.ssns?).to eq(false)
        expect(result.ssn_mapping).to eq({})

        expect(result.phone_numbers).to eq([])
        expect(result.phone_numbers?).to eq(false)
        expect(result.phone_number_mapping).to eq({})
      end
    end

    context "when a custom label is used" do
      it "categorizes sensitive information from free text using that label" do
        input = "user[at]example.com"

        result = TopSecret::Text.filter(input, email_filter: TopSecret::Filters::Regex.new(
          label: "EMAIL_ADDRESS",
          regex: /user\[at\]example\.com/
        ))

        expect(result.email_addresses).to eq([input])
        expect(result.email_addresses?).to eq(true)
        expect(result.email_address_mapping).to eq({EMAIL_ADDRESS_1: input})
      end

      it "categorizes sensitive information from free text using the default label" do
        input = "user[at]example.com"

        result = TopSecret::Text.filter(input, email_filter: TopSecret::Filters::Regex.new(
          label: "E_MAIL_ADDRESS",
          regex: /user\[at\]example\.com/
        ))

        expect(result.emails).to eq([input])
        expect(result.emails?).to eq(true)
        expect(result.email_mapping).to eq({EMAIL_ADDRESS_1: input})
      end
    end

    context "when the filters option is passed" do
      it "overrides existing Regex filters" do
        input = <<~TEXT
          My name is Ralph
          My location is Boston
          My email address is user[at]example.com
          My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
          My social security number is 123-45-6789
          My phone number is 555-555-5555
        TEXT

        result = TopSecret::Text.filter(input, email_filter: TopSecret::Filters::Regex.new(
          label: "EMAIL_ADDRESS",
          regex: /user\[at\]example\.com/
        ))

        expect(result.output).to eq(<<~TEXT)
          My name is [PERSON_1]
          My location is [LOCATION_1]
          My email address is [EMAIL_ADDRESS_1]
          My credit card numbers are [CREDIT_CARD_1] and [CREDIT_CARD_2]
          My social security number is [SSN_1]
          My phone number is [PHONE_NUMBER_1]
        TEXT
        expect(result.mapping).to eq({
          EMAIL_ADDRESS_1: "user[at]example.com",
          CREDIT_CARD_1: "4242-4242-4242-4242",
          CREDIT_CARD_2: "4141414141414141",
          SSN_1: "123-45-6789",
          PHONE_NUMBER_1: "555-555-5555",
          PERSON_1: "Ralph",
          LOCATION_1: "Boston"
        })
        expect(result.input).to eq(input)
      end

      it "overrides existing NER filters" do
        score = 0.25
        ralph = build_entity(text: "Ralph", tag: :person, score:)
        stub_ner_entities(ralph, boston)

        input = <<~TEXT
          My name is Ralph
          My location is Boston
          My email address is user@example.com
          My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
          My social security number is 123-45-6789
          My phone number is 555-555-5555
        TEXT

        result = TopSecret::Text.filter(input, people_filter: TopSecret::Filters::NER.new(
          label: "NAME",
          tag: :person,
          min_confidence_score: score
        ))

        expect(result.output).to eq(<<~TEXT)
          My name is [NAME_1]
          My location is [LOCATION_1]
          My email address is [EMAIL_1]
          My credit card numbers are [CREDIT_CARD_1] and [CREDIT_CARD_2]
          My social security number is [SSN_1]
          My phone number is [PHONE_NUMBER_1]
        TEXT
        expect(result.mapping).to eq({
          EMAIL_1: "user@example.com",
          CREDIT_CARD_1: "4242-4242-4242-4242",
          CREDIT_CARD_2: "4141414141414141",
          SSN_1: "123-45-6789",
          PHONE_NUMBER_1: "555-555-5555",
          NAME_1: "Ralph",
          LOCATION_1: "Boston"
        })
        expect(result.input).to eq(input)
      end

      it "ignores existing filters" do
        input = <<~TEXT
          My name is Ralph
          My location is Boston
          My email address is user@example.com
          My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
          My social security number is 123-45-6789
          My phone number is 555-555-5555
        TEXT

        result = TopSecret::Text.filter(input, email_filter: nil)

        expect(result.output).to eq(<<~TEXT)
          My name is [PERSON_1]
          My location is [LOCATION_1]
          My email address is user@example.com
          My credit card numbers are [CREDIT_CARD_1] and [CREDIT_CARD_2]
          My social security number is [SSN_1]
          My phone number is [PHONE_NUMBER_1]
        TEXT
        expect(result.mapping).to eq({
          CREDIT_CARD_1: "4242-4242-4242-4242",
          CREDIT_CARD_2: "4141414141414141",
          SSN_1: "123-45-6789",
          PHONE_NUMBER_1: "555-555-5555",
          PERSON_1: "Ralph",
          LOCATION_1: "Boston"
        })
        expect(result.input).to eq(input)
      end

      it "respects new Regex filters" do
        input = <<~TEXT
          My name is Ralph
          My location is Boston
          My email address is user@example.com
          My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
          My social security number is 123-45-6789
          My phone number is 555-555-5555
          My IP address is 192.168.1.1
        TEXT

        result = TopSecret::Text.filter(input, custom_filters: [TopSecret::Filters::Regex.new(
          label: "IP_ADDRESS",
          regex: /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/
        )])

        expect(result.output).to eq(<<~TEXT)
          My name is [PERSON_1]
          My location is [LOCATION_1]
          My email address is [EMAIL_1]
          My credit card numbers are [CREDIT_CARD_1] and [CREDIT_CARD_2]
          My social security number is [SSN_1]
          My phone number is [PHONE_NUMBER_1]
          My IP address is [IP_ADDRESS_1]
        TEXT
        expect(result.mapping).to eq({
          EMAIL_1: "user@example.com",
          CREDIT_CARD_1: "4242-4242-4242-4242",
          CREDIT_CARD_2: "4141414141414141",
          SSN_1: "123-45-6789",
          PHONE_NUMBER_1: "555-555-5555",
          PERSON_1: "Ralph",
          LOCATION_1: "Boston",
          IP_ADDRESS_1: "192.168.1.1"
        })
        expect(result.input).to eq(input)
      end

      it "respects new NER filters" do
        ip_address = build_entity(text: "192.168.1.1", tag: :ip_address)
        stub_ner_entities(ralph, boston, ip_address)

        input = <<~TEXT
          My name is Ralph
          My location is Boston
          My email address is user@example.com
          My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
          My social security number is 123-45-6789
          My phone number is 555-555-5555
          My IP address is 192.168.1.1
        TEXT

        result = TopSecret::Text.filter(input, custom_filters: [TopSecret::Filters::NER.new(
          label: "IP_ADDRESS",
          tag: :ip_address
        )])

        expect(result.output).to eq(<<~TEXT)
          My name is [PERSON_1]
          My location is [LOCATION_1]
          My email address is [EMAIL_1]
          My credit card numbers are [CREDIT_CARD_1] and [CREDIT_CARD_2]
          My social security number is [SSN_1]
          My phone number is [PHONE_NUMBER_1]
          My IP address is [IP_ADDRESS_1]
        TEXT
        expect(result.mapping).to eq({
          EMAIL_1: "user@example.com",
          CREDIT_CARD_1: "4242-4242-4242-4242",
          CREDIT_CARD_2: "4141414141414141",
          SSN_1: "123-45-6789",
          PHONE_NUMBER_1: "555-555-5555",
          PERSON_1: "Ralph",
          LOCATION_1: "Boston",
          IP_ADDRESS_1: "192.168.1.1"
        })
        expect(result.input).to eq(input)
      end

      it "ignores invalid options" do
        input = "192.168.1.1"
        ip_address_filter = TopSecret::Filters::Regex.new(
          label: "IP_ADDRESS",
          regex: /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/
        )

        expect { TopSecret::Text.filter(input, ip_address_filter:) }.to raise_error(ArgumentError)
      end
    end

    it "removes duplicate entries from the mapping" do
      result = TopSecret::Text.filter("user@example.com user@example.com")

      expect(result.mapping.fetch(:EMAIL_1)).to eq("user@example.com")
    end

    it "filters email addresses from free text" do
      result = TopSecret::Text.filter("user@example.com")

      expect(result.output).to eq("[EMAIL_1]")
    end

    it "filters delimited credit card numbers from free text" do
      result = TopSecret::Text.filter("4242-4242-4242-4242")

      expect(result.output).to eq("[CREDIT_CARD_1]")
    end

    it "filters non-delimited credit card numbers from free text" do
      result = TopSecret::Text.filter("4242424242424242")

      expect(result.output).to eq("[CREDIT_CARD_1]")
    end

    it "filters social security numbers from free text" do
      result = TopSecret::Text.filter("123-45-6789")

      expect(result.output).to eq("[SSN_1]")
    end

    it "filters phone numbers from free text" do
      result = TopSecret::Text.filter("555-555-5555")

      expect(result.output).to eq("[PHONE_NUMBER_1]")
    end

    it "filters names from free text" do
      result = TopSecret::Text.filter("Ralph")

      expect(result.output).to eq("[PERSON_1]")
    end

    it "filters locations from free text" do
      result = TopSecret::Text.filter("Boston")

      expect(result.output).to eq("[LOCATION_1]")
    end

    it "returns a TopSecret::Text::Result" do
      result = TopSecret::Text.filter("")

      expect(result).to be_an_instance_of(TopSecret::Text::Result)
    end

    context "when there are multiple unique email addresses" do
      it "filters each email address from free text" do
        result = TopSecret::Text.filter("user_1@example.com user_2@example.com")

        expect(result.output).to eq("[EMAIL_1] [EMAIL_2]")
      end
    end

    context "when there are multiple identical email addresses" do
      it "filters each email address from free text, and maps them to the same filter" do
        result = TopSecret::Text.filter("user_1@example.com user_1@example.com")

        expect(result.output).to eq("[EMAIL_1] [EMAIL_1]")
      end
    end

    context "when there are multiple unique credit card numbers" do
      it "filters each credit card number from free text" do
        input = <<~TEXT
          4242-4242-4242-4242
          4141-4141-4141-4141
          4242424242424242
          4141414141414141
        TEXT

        result = TopSecret::Text.filter(input)

        expect(result.output).to eq(<<~TEXT)
          [CREDIT_CARD_1]
          [CREDIT_CARD_2]
          [CREDIT_CARD_3]
          [CREDIT_CARD_4]
        TEXT
      end
    end

    context "when there are multiple identical credit card numbers" do
      it "filters each credit card number from free text, and maps to the same filter" do
        input = <<~TEXT
          4242-4242-4242-4242
          4242-4242-4242-4242
          4141-4141-4141-4141
          4141-4141-4141-4141
          4242424242424242
          4242424242424242
          4141414141414141
          4141414141414141
        TEXT

        result = TopSecret::Text.filter(input)

        expect(result.output).to eq(<<~TEXT)
          [CREDIT_CARD_1]
          [CREDIT_CARD_1]
          [CREDIT_CARD_2]
          [CREDIT_CARD_2]
          [CREDIT_CARD_3]
          [CREDIT_CARD_3]
          [CREDIT_CARD_4]
          [CREDIT_CARD_4]
        TEXT
      end
    end

    context "when there are multiple unique social security numbers" do
      it "filters each social security number from free text" do
        result = TopSecret::Text.filter("123-45-6789 000-00-0000")

        expect(result.output).to eq("[SSN_1] [SSN_2]")
      end
    end

    context "when there are multiple identical social security numbers" do
      it "filters each social security number from free text, and maps them to the same filter" do
        result = TopSecret::Text.filter("123-45-6789 123-45-6789")

        expect(result.output).to eq("[SSN_1] [SSN_1]")
      end
    end

    context "when there are multiple unique phone numbers" do
      it "filters each phone number from free text" do
        result = TopSecret::Text.filter("555-555-5555 444-444-4444")

        expect(result.output).to eq("[PHONE_NUMBER_1] [PHONE_NUMBER_2]")
      end
    end

    context "when there are multiple identical phone numbers" do
      it "filters each phone number from free text, and maps them to the same filter" do
        result = TopSecret::Text.filter("555-555-5555 555-555-5555")

        expect(result.output).to eq("[PHONE_NUMBER_1] [PHONE_NUMBER_1]")
      end
    end

    context "when there are multiple unique people" do
      before do
        ralph = build_entity(text: "Ralph", tag: :person)
        ruby = build_entity(text: "Ruby", tag: :person)
        stub_ner_entities(ralph, ruby)
      end

      it "filters each person from free text" do
        result = TopSecret::Text.filter("Ralph Ruby")

        expect(result.output).to eq("[PERSON_1] [PERSON_2]")
      end
    end

    context "when there are multiple identical people" do
      before do
        ralph_1 = build_entity(text: "Ralph", tag: :person)
        ralph_2 = build_entity(text: "Ralph", tag: :person)
        stub_ner_entities(ralph_1, ralph_2)
      end

      it "filters each person from free text, and maps them to the same filter" do
        result = TopSecret::Text.filter("Ralph Ralph")

        expect(result.output).to eq("[PERSON_1] [PERSON_1]")
      end
    end

    context "when the confidence score is below the threshold for a person" do
      before do
        score = TopSecret.min_confidence_score - 0.1
        ralph = build_entity(text: "Ralph", tag: :person, score:)
        stub_ner_entities(ralph)
      end

      it "does not filter the person from free text" do
        result = TopSecret::Text.filter("Ralph")

        expect(result.output).to eq("Ralph")
      end
    end

    context "when there are multiple unique locations" do
      before do
        boston = build_entity(text: "Boston", tag: :location)
        new_york = build_entity(text: "New York", tag: :location)
        stub_ner_entities(boston, new_york)
      end

      it "filters each location from free text" do
        result = TopSecret::Text.filter("Boston New York")

        expect(result.output).to eq("[LOCATION_1] [LOCATION_2]")
      end
    end

    context "when there are multiple identical locations" do
      before do
        boston_1 = build_entity(text: "Boston", tag: :location)
        boston_2 = build_entity(text: "Boston", tag: :location)
        stub_ner_entities(boston_1, boston_2)
      end

      it "filters each location from free text, and maps them to the same filter" do
        result = TopSecret::Text.filter("Boston Boston")

        expect(result.output).to eq("[LOCATION_1] [LOCATION_1]")
      end
    end

    context "when the confidence score is below the threshold for a location" do
      before do
        score = TopSecret.min_confidence_score - 0.1
        boston = build_entity(text: "Boston", tag: :location, score:)
        stub_ner_entities(boston)
      end

      it "does not filter the location from free text" do
        result = TopSecret::Text.filter("Boston")

        expect(result.output).to eq("Boston")
      end
    end

    context "when a malformed label is passed" do
      %w[
        _EMAIL_ADDRESS
        EMAIL_ADDRESS_
        1EMAIL_ADDRESS
        EMAIL_ADDRESS1
        1_EMAIL_ADDRESS
        EMAIL_ADDRESS_1
        *EMAIL_ADDRESS
        EMAIL_ADDRESS*
        EMAIL__ADDRESS
        EMAIL*ADDRESS
        EMAIL1ADDRESS
      ].each do |invalid_label|
        it "raises when label is '#{invalid_label}'" do
          expect {
            TopSecret::Text.filter("", email_filter: TopSecret::Filters::Regex.new(
              label: invalid_label,
              regex: /user\[at\]example\.com/
            ))
          }.to raise_error(TopSecret::Error::MalformedLabel, "Unsupported label. Labels must contain only letters and underscores: '#{invalid_label}'")
        end
      end

      [
        "",
        " ",
        nil
      ].each do |blank_label|
        it "raises raises when label is '#{blank_label}'" do
          expect {
            TopSecret::Text.filter("", email_filter: TopSecret::Filters::Regex.new(
              label: blank_label,
              regex: /user\[at\]example\.com/
            ))
          }.to raise_error(TopSecret::Error::MalformedLabel, "You must provide a label.")
        end
      end
    end
  end

  describe ".filter_all" do
    before do
      stub_ner_entities
    end

    it "filters sensitive information from a list of free text and creates a mapping" do
      messages = [
        "My email is ralph@example.com, and my credit card number is 4242424242424242",
        "I'll email ruby@example.com, and send her my new credit card number, which is 4141414141414141",
        "Please charge 4242424242424242 and email ruby@example.com and ralph@example.com",
        "This sentence contains no sensitive information"
      ]

      result = TopSecret::Text.filter_all(messages)

      aggregate_failures "test filters" do
        expect(result.mapping).to eq({
          EMAIL_1: "ralph@example.com",
          EMAIL_2: "ruby@example.com",
          CREDIT_CARD_1: "4242424242424242",
          CREDIT_CARD_2: "4141414141414141"
        })
        expect(result.items.map(&:input)).to eq(messages)
        expect(result.items.map(&:output)).to eq([
          "My email is [EMAIL_1], and my credit card number is [CREDIT_CARD_1]",
          "I'll email [EMAIL_2], and send her my new credit card number, which is [CREDIT_CARD_2]",
          "Please charge [CREDIT_CARD_1] and email [EMAIL_2] and [EMAIL_1]",
          "This sentence contains no sensitive information"
        ])
        expect(result.items.map(&:mapping)).to eq([
          {EMAIL_1: "ralph@example.com", CREDIT_CARD_1: "4242424242424242"},
          {EMAIL_2: "ruby@example.com", CREDIT_CARD_2: "4141414141414141"},
          {EMAIL_1: "ralph@example.com", EMAIL_2: "ruby@example.com", CREDIT_CARD_1: "4242424242424242"},
          {}
        ])
        expect(result.items.map(&:sensitive?)).to eq([
          true,
          true,
          true,
          false
        ])
        expect(result.items.map(&:safe?)).to eq([
          false,
          false,
          false,
          true
        ])
      end
    end

    it "categorizes sensitive information from free text" do
      result = TopSecret::Text.filter_all([
        "user@example.com"
      ])

      expect(result.items.map(&:emails)).to eq([["user@example.com"]])
      expect(result.items.map(&:emails?)).to eq([true])
      expect(result.items.map(&:email_mapping)).to eq([{EMAIL_1: "user@example.com"}])
    end

    context "when there is no sensitive information" do
      it "responds to the default filters" do
        result = TopSecret::Text.filter_all([""])

        expect(result.items.map(&:emails)).to eq([[]])
        expect(result.items.map(&:emails?)).to eq([false])
        expect(result.items.map(&:email_mapping)).to eq([{}])

        expect(result.items.map(&:credit_cards)).to eq([[]])
        expect(result.items.map(&:credit_cards?)).to eq([false])
        expect(result.items.map(&:credit_card_mapping)).to eq([{}])

        expect(result.items.map(&:phone_numbers)).to eq([[]])
        expect(result.items.map(&:phone_numbers?)).to eq([false])
        expect(result.items.map(&:phone_number_mapping)).to eq([{}])

        expect(result.items.map(&:ssns)).to eq([[]])
        expect(result.items.map(&:ssns?)).to eq([false])
        expect(result.items.map(&:ssn_mapping)).to eq([{}])

        expect(result.items.map(&:people)).to eq([[]])
        expect(result.items.map(&:people?)).to eq([false])
        expect(result.items.map(&:person_mapping)).to eq([{}])

        expect(result.items.map(&:locations)).to eq([[]])
        expect(result.items.map(&:locations?)).to eq([false])
        expect(result.items.map(&:location_mapping)).to eq([{}])
      end
    end

    it "returns TopSecret::Text::BatchResult" do
      result = TopSecret::Text.filter_all(["", ""])

      expect(result).to be_an_instance_of(TopSecret::Text::BatchResult)
    end

    context "when the filters option is passed" do
      it "overrides existing Regex filters" do
        messages = [
          "ralph[at]example.com 4141414141414141 ruby[at]example.com 4242424242424242",
          "4242424242424242 ruby[at]example.com 4141414141414141 ralph[at]example.com"
        ]
        email_filter = TopSecret::Filters::Regex.new(label: "EMAIL_ADDRESS", regex: /\b\w+\[at\]\w+\.\w+\b/)

        result = TopSecret::Text.filter_all(messages, email_filter:)

        expect(result.mapping).to eq({
          EMAIL_ADDRESS_1: "ralph[at]example.com",
          EMAIL_ADDRESS_2: "ruby[at]example.com",
          CREDIT_CARD_1: "4141414141414141",
          CREDIT_CARD_2: "4242424242424242"
        })
        expect(result.items.map(&:input)).to eq(messages)
        expect(result.items.map(&:output)).to eq([
          "[EMAIL_ADDRESS_1] [CREDIT_CARD_1] [EMAIL_ADDRESS_2] [CREDIT_CARD_2]",
          "[CREDIT_CARD_2] [EMAIL_ADDRESS_2] [CREDIT_CARD_1] [EMAIL_ADDRESS_1]"
        ])
      end

      it "overrides existing NER filters" do
        score = 0.25
        ralph = build_entity(text: "Ralph", tag: :person, score:)
        ruby = build_entity(text: "Ruby", tag: :person, score:)
        stub_ner_entities(ralph, ruby)

        messages = [
          "Ralph 4141414141414141 Ruby 4242424242424242",
          "4242424242424242 Ruby 4141414141414141 Ralph"
        ]
        people_filter = TopSecret::Filters::NER.new(
          label: "NAME",
          tag: :person,
          min_confidence_score: score
        )

        result = TopSecret::Text.filter_all(messages, people_filter:)

        expect(result.mapping).to eq({
          NAME_1: "Ralph",
          NAME_2: "Ruby",
          CREDIT_CARD_1: "4141414141414141",
          CREDIT_CARD_2: "4242424242424242"
        })
        expect(result.items.map(&:input)).to eq(messages)
        expect(result.items.map(&:output)).to eq([
          "[NAME_1] [CREDIT_CARD_1] [NAME_2] [CREDIT_CARD_2]",
          "[CREDIT_CARD_2] [NAME_2] [CREDIT_CARD_1] [NAME_1]"
        ])
      end

      it "ignores existing filters" do
        messages = [
          "ralph@example.com 4141414141414141 ruby@example.com 4242424242424242",
          "4242424242424242 ruby@example.com 4141414141414141 ralph@example.com"
        ]

        result = TopSecret::Text.filter_all(messages, email_filter: nil)

        expect(result.mapping).to eq({
          CREDIT_CARD_1: "4141414141414141",
          CREDIT_CARD_2: "4242424242424242"
        })
        expect(result.items.map(&:input)).to eq(messages)
        expect(result.items.map(&:output)).to eq([
          "ralph@example.com [CREDIT_CARD_1] ruby@example.com [CREDIT_CARD_2]",
          "[CREDIT_CARD_2] ruby@example.com [CREDIT_CARD_1] ralph@example.com"
        ])
      end

      it "respects new Regex filters" do
        messages = [
          "192.168.1.1 4141414141414141 127.0.0.1 4242424242424242",
          "4242424242424242 127.0.0.1 4141414141414141 192.168.1.1"
        ]
        ip_address_filter = TopSecret::Filters::Regex.new(
          label: "IP_ADDRESS",
          regex: /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/
        )

        result = TopSecret::Text.filter_all(messages, custom_filters: [ip_address_filter])

        expect(result.mapping).to eq({
          IP_ADDRESS_1: "192.168.1.1",
          IP_ADDRESS_2: "127.0.0.1",
          CREDIT_CARD_1: "4141414141414141",
          CREDIT_CARD_2: "4242424242424242"
        })
        expect(result.items.map(&:input)).to eq(messages)
        expect(result.items.map(&:output)).to eq([
          "[IP_ADDRESS_1] [CREDIT_CARD_1] [IP_ADDRESS_2] [CREDIT_CARD_2]",
          "[CREDIT_CARD_2] [IP_ADDRESS_2] [CREDIT_CARD_1] [IP_ADDRESS_1]"
        ])
      end

      it "respects new NER filters" do
        ip_addresses = [
          build_entity(text: "192.168.1.1", tag: :ip_address),
          build_entity(text: "127.0.0.1", tag: :ip_address)
        ]
        stub_ner_entities(*ip_addresses)
        messages = [
          "192.168.1.1 4141414141414141 127.0.0.1 4242424242424242",
          "4242424242424242 127.0.0.1 4141414141414141 192.168.1.1"
        ]
        ip_address_filter = TopSecret::Filters::NER.new(
          label: "IP_ADDRESS",
          tag: :ip_address
        )

        result = TopSecret::Text.filter_all(messages, custom_filters: [ip_address_filter])

        expect(result.mapping).to eq({
          IP_ADDRESS_1: "192.168.1.1",
          IP_ADDRESS_2: "127.0.0.1",
          CREDIT_CARD_1: "4141414141414141",
          CREDIT_CARD_2: "4242424242424242"
        })
        expect(result.items.map(&:input)).to eq(messages)
        expect(result.items.map(&:output)).to eq([
          "[IP_ADDRESS_1] [CREDIT_CARD_1] [IP_ADDRESS_2] [CREDIT_CARD_2]",
          "[CREDIT_CARD_2] [IP_ADDRESS_2] [CREDIT_CARD_1] [IP_ADDRESS_1]"
        ])
      end
    end
  end

  describe ".scan" do
    let(:ralph) { build_entity(text: "Ralph", tag: :person) }
    let(:boston) { build_entity(text: "Boston", tag: :location) }

    before do
      stub_ner_entities(ralph, boston)
    end

    it "determines if sensitive information exists in free text and creates a mapping" do
      input = <<~TEXT
        My name is Ralph
        My location is Boston
        My email address is user@example.com
        My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
        My social security number is 123-45-6789
        My phone number is 555-555-5555
      TEXT

      result = TopSecret::Text.scan(input)

      expect(result.sensitive?).to eq(true)
      expect(result.mapping).to eq({
        EMAIL_1: "user@example.com",
        CREDIT_CARD_1: "4242-4242-4242-4242",
        CREDIT_CARD_2: "4141414141414141",
        SSN_1: "123-45-6789",
        PHONE_NUMBER_1: "555-555-5555",
        PERSON_1: "Ralph",
        LOCATION_1: "Boston"
      })
    end

    context "when the filters option is passed" do
      it "overrides existing Regex filters" do
        input = <<~TEXT
          My name is Ralph
          My location is Boston
          My email address is user[at]example.com
          My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
          My social security number is 123-45-6789
          My phone number is 555-555-5555
        TEXT

        result = TopSecret::Text.scan(input, email_filter: TopSecret::Filters::Regex.new(
          label: "EMAIL_ADDRESS",
          regex: /user\[at\]example\.com/
        ))

        expect(result.sensitive?).to eq(true)
        expect(result.mapping).to eq({
          EMAIL_ADDRESS_1: "user[at]example.com",
          CREDIT_CARD_1: "4242-4242-4242-4242",
          CREDIT_CARD_2: "4141414141414141",
          SSN_1: "123-45-6789",
          PHONE_NUMBER_1: "555-555-5555",
          PERSON_1: "Ralph",
          LOCATION_1: "Boston"
        })
      end

      it "overrides existing NER filters" do
        score = 0.25
        ralph = build_entity(text: "Ralph", tag: :person, score:)
        stub_ner_entities(ralph, boston)

        input = <<~TEXT
          My name is Ralph
          My location is Boston
          My email address is user@example.com
          My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
          My social security number is 123-45-6789
          My phone number is 555-555-5555
        TEXT

        result = TopSecret::Text.scan(input, people_filter: TopSecret::Filters::NER.new(
          label: "NAME",
          tag: :person,
          min_confidence_score: score
        ))

        expect(result.sensitive?).to eq(true)
        expect(result.mapping).to eq({
          EMAIL_1: "user@example.com",
          CREDIT_CARD_1: "4242-4242-4242-4242",
          CREDIT_CARD_2: "4141414141414141",
          SSN_1: "123-45-6789",
          PHONE_NUMBER_1: "555-555-5555",
          NAME_1: "Ralph",
          LOCATION_1: "Boston"
        })
      end

      it "ignores existing filters" do
        input = <<~TEXT
          My name is Ralph
          My location is Boston
          My email address is user@example.com
          My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
          My social security number is 123-45-6789
          My phone number is 555-555-5555
        TEXT

        result = TopSecret::Text.scan(input, email_filter: nil)

        expect(result.sensitive?).to eq(true)
        expect(result.mapping).to eq({
          CREDIT_CARD_1: "4242-4242-4242-4242",
          CREDIT_CARD_2: "4141414141414141",
          SSN_1: "123-45-6789",
          PHONE_NUMBER_1: "555-555-5555",
          PERSON_1: "Ralph",
          LOCATION_1: "Boston"
        })
      end

      it "respects new Regex filters" do
        input = <<~TEXT
          My name is Ralph
          My location is Boston
          My email address is user@example.com
          My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
          My social security number is 123-45-6789
          My phone number is 555-555-5555
          My IP address is 192.168.1.1
        TEXT

        result = TopSecret::Text.scan(input, custom_filters: [TopSecret::Filters::Regex.new(
          label: "IP_ADDRESS",
          regex: /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/
        )])

        expect(result.sensitive?).to eq(true)
        expect(result.mapping).to eq({
          EMAIL_1: "user@example.com",
          CREDIT_CARD_1: "4242-4242-4242-4242",
          CREDIT_CARD_2: "4141414141414141",
          SSN_1: "123-45-6789",
          PHONE_NUMBER_1: "555-555-5555",
          PERSON_1: "Ralph",
          LOCATION_1: "Boston",
          IP_ADDRESS_1: "192.168.1.1"
        })
      end

      it "respects new NER filters" do
        ip_address = build_entity(text: "192.168.1.1", tag: :ip_address)
        stub_ner_entities(ralph, boston, ip_address)

        input = <<~TEXT
          My name is Ralph
          My location is Boston
          My email address is user@example.com
          My credit card numbers are 4242-4242-4242-4242 and 4141414141414141
          My social security number is 123-45-6789
          My phone number is 555-555-5555
          My IP address is 192.168.1.1
        TEXT

        result = TopSecret::Text.scan(input, custom_filters: [TopSecret::Filters::NER.new(
          label: "IP_ADDRESS",
          tag: :ip_address
        )])

        expect(result.sensitive?).to eq(true)
        expect(result.mapping).to eq({
          EMAIL_1: "user@example.com",
          CREDIT_CARD_1: "4242-4242-4242-4242",
          CREDIT_CARD_2: "4141414141414141",
          SSN_1: "123-45-6789",
          PHONE_NUMBER_1: "555-555-5555",
          PERSON_1: "Ralph",
          LOCATION_1: "Boston",
          IP_ADDRESS_1: "192.168.1.1"
        })
      end

      it "ignores invalid options" do
        input = "192.168.1.1"
        ip_address_filter = TopSecret::Filters::Regex.new(
          label: "IP_ADDRESS",
          regex: /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/
        )

        expect { TopSecret::Text.scan(input, ip_address_filter:) }.to raise_error(ArgumentError)
      end
    end
  end
end
