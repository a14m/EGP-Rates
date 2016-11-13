# frozen_string_literal: true

require 'oga'
require 'json'
require 'egp_rates/bank'
require 'egp_rates/cbe'
require 'egp_rates/nbe'
require 'egp_rates/cib'
require 'egp_rates/aaib'

# Base Module
module EGPRates
  # Class Idicating HTTPResponseErrors when unexpected behaviour encountered
  # while scraping the [Bank] data
  class ResponseError < StandardError
  end
end
