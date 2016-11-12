# EGPRates
[![wercker status](https://app.wercker.com/status/d6ca4529f0d563e82898ace1f2b3de25/s/master "wercker status")](https://app.wercker.com/project/byKey/d6ca4529f0d563e82898ace1f2b3de25)
[![Code Climate](https://codeclimate.com/github/mad-raz/EGP-Rates/badges/gpa.svg)](https://codeclimate.com/github/mad-raz/EGP-Rates)
[![Test Coverage](https://codeclimate.com/github/mad-raz/EGP-Rates/badges/coverage.svg)](https://codeclimate.com/github/mad-raz/EGP-Rates/coverage)
[![Gem Version](https://badge.fury.io/rb/EGP_Rates.svg)](https://rubygems.org/gems/EGP_Rates)
[![LICENSE](https://img.shields.io/badge/licence-MIT-blue.svg)](/LICENSE.md)

## Installation

Add this line to your application's Gemfile:
```ruby
gem 'EGP_Rates'
```
And then execute:
```sh
$ bundle
```
Or install it yourself as:
```sh
$ gem install EGP_Rates
```

## Usage
- Scrape all available Banks (WIP)
- Scrape [Central Bank of Egypt (CBE)](/lib/egp_rates/cbe.rb)
- Scrape [National Bank of Egypt (NBE)](/lib/egp_rates/nbe.rb)
- Scrape [Commercial International Bank (CIB)](/lib/egp_rates/cib.rb)

```rb
EGPRates::CBE.new.exchange_rates
EGPRates::NBE.new.exchange_rates
EGPRates::CIB.new.exchange_rates
```

## Development
- clone the repo
- to install dependencies run `bundle install`
- to run the test suite `bundle exec rake spec`
- to run rubocop linter `bundle exec rake rubocop`

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/mad-raz/EGP_Rates

This project is intended to be a safe,
welcoming space for collaboration,
and contributors are expected to adhere to the
Contributor Covenant [code of conduct.](/CODE_OF_CONDUCT.md)

- Read the previous [code of conduct](/CODE_OF_CONDUCT.md) once again.
- Write clean code.
- Write clean tests.
- Make sure your code is covered by test.
- Make sure you follow the code style mentioned by
[rubocop](http://batsov.com/rubocop/) (run `bundle exec rake rubocop`)
- A pre-commit hook included with repo can be used to remember rubocop
it won't disable commits, but will remind you of violations.
you can set it up using `chmod +x pre-commit && cp pre-commit .git/hooks/`
- Be nice to your fellow human-beings/bots contributing to this repo.

## License

The project is available as open source under the terms of the
[MIT License](/LICENSE.md)
