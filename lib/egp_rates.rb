# frozen_string_literal: true

require 'oga'
require 'egp_rates/bank'
require 'egp_rates/cbe'
require 'egp_rates/nbe'

# Base Module
module EGPRates
  # Class Idicating HTTPResponseErrors when unexpected behaviour encountered
  # while scraping the [Bank] data
  class ResponseError < StandardError
  end
end
