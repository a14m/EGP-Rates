# EGPRates
[![wercker status](https://app.wercker.com/status/d6ca4529f0d563e82898ace1f2b3de25/s/master "wercker status")](https://app.wercker.com/project/byKey/d6ca4529f0d563e82898ace1f2b3de25)
[![Code Climate](https://codeclimate.com/github/mad-raz/EGP-Rates/badges/gpa.svg)](https://codeclimate.com/github/mad-raz/EGP-Rates)
[![Test Coverage](https://codeclimate.com/github/mad-raz/EGP-Rates/badges/coverage.svg)](https://codeclimate.com/github/mad-raz/EGP-Rates/coverage)
[![LICENSE](https://img.shields.io/badge/licence-MIT-blue.svg)](/LICENSE.md)

[CLI available here](https://github.com/mad-raz/EGP-Rates-CLI)

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
- [Get all the available banks rates](/lib/egp_rates.rb)
- [Central Bank of Egypt (CBE)](/lib/egp_rates/cbe.rb)
- [National Bank of Egypt (NBE)](/lib/egp_rates/nbe.rb)
- [Commercial International Bank (CIB)](/lib/egp_rates/cib.rb)
- [Arab African International Bank (AAIB)](/lib/egp_rates/aaib.rb)
- [Banque Du Caire](/lib/egp_rates/banque_du_caire.rb)
- [Banque Misr](/lib/egp_rates/banque_misr.rb)
- [Suez Canal Bank](/lib/egp_rates/suez_canal_bank.rb)
- [Al Baraka Bank](/lib/egp_rates/al_baraka_bank.rb)
- [Al Ahli Bank of Kuwait](/lib/egp_rates/al_ahli_bank_of_kuwait.rb)
- [Société Arabe Internationale de Banque (SAIB)](/lib/egp_rates/saib.rb)
- [Misr Iran Development Bank (MIDB)](/lib/egp_rates/midb.rb)
- [The United Bank of Egypt (UBE)](/lib/egp_rates/ube.rb)
- [Crédit Agricole Egypt (CAE)](/lib/egp_rates/cae.rb)
- [Export Development Bank of Egypt (EDBE)](/lib/egp_rates/edbe.rb)
- [Bank of Alexandria (AlexBank)](/lib/egp_rates/alex_bank.rb)
- [Blom Bank Egypt (Blom)](/lib/egp_rates/blom.rb)
- [Abu Dhabi Islamic Bank (ADIB)](/lib/egp_rates/adib.rb)
- [Egyptian Gulf Bank (EGB)](/lib/egp_rates/egb.rb)
- [National Bank of Greece (NBG)](/lib/egp_rates/nbg.rb)
- [Faisal Islamic Bank](/lib/egp_rates/faisal_bank.rb)

```rb
require 'egp_rates'
# All Available Banks Data (Threaded execution)
# For all the currencies that the currently showing on their pages
EGPRates.exchange_rates

# All Available Banks Data about specific currency
# (by default it caches the response for later use)
EGPRates.exchange_rate :USD        # call and cache response
EGPRates.exchange_rate :eur        # from cached response
EGPRates.exchange_rate :EUR, false # refresh cache

# Specific Bank Data
EGPRates::CBE.new.exchange_rates
EGPRates::NBE.new.exchange_rates
EGPRates::CIB.new.exchange_rates
EGPRates::AAIB.new.exchange_rates
EGPRates::BanqueDuCaire.new.exchange_rates
EGPRates::BanqueMisr.new.exchange_rates
EGPRates::SuezCanalBank.new.exchange_rates
EGPRates::AlBarakaBank.new.exchange_rates
EGPRates::AlAhliBankOfKuwait.new.exchange_rates
EGPRates::SAIB.new.exchange_rates
EGPRates::MIDB.new.exchange_rates
EGPRates::UBE.new.exchange_rates
EGPRates::CAE.new.exchange_rates
EGPRates::EDBE.new.exchange_rates
EGPRates::AlexBank.new.exchange_rates
EGPRates::Blom.new.exchange_rates
EGPRates::ADIB.new.exchange_rates
EGPRates::EGB.new.exchange_rates
EGPRates::NBG.new.exchange_rates
EGPRates::FaisalBank.new.exchange_rates
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
