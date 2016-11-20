# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'EGP_Rates'
  spec.version       = '0.3.0'
  spec.authors       = ['Ahmed Abdel-Razzak']
  spec.email         = ['abdelrazzak.ahmed@gmail.com']

  spec.summary       = 'Scrape EGP exchange rate from different EG Banks'
  spec.homepage      = 'https://github.com/mad-raz/EGP-Rates'
  spec.license       = 'MIT'
  spec.required_ruby_version = '~>2.3.0'

  spec.files         = Dir['lib/**/*.rb'] + Dir['spec/**/*']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'codeclimate-test-reporter'

  spec.add_dependency 'oga'
end
