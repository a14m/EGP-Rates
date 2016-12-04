# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'
require 'webmock/rspec'
require 'vcr'
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'egp_rates'

WebMock.disable_net_connect!

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = false
  config.configure_rspec_metadata!
  config.default_cassette_options[:serialize_with] = :compressed
end

RSpec.configure do |config|
  config.order = 'random'

  config.around(:each) do |ex|
    if ex.metadata.key?(:live)
      WebMock.allow_net_connect!
      VCR.turned_off { ex.run }
      WebMock.disable_net_connect!
    elsif ex.metadata.key?(:no_vcr)
      VCR.turned_off { ex.run }
    elsif ex.metadata.key?(:vcr)
      VCR.configuration.default_cassette_options[:record] = :once
      ex.run
    else
      ex.run
    end
  end
end
