# frozen_string_literal: true

require 'oga'
require 'egp_rates/bank'
require 'egp_rates/cbe'

# Base Module
module EGPRates
  # Class Idicating HTTPResponseErrors when unexpected behaviour encountered
  # while scraping the [Bank] data
  class ResponseError < StandardError
  end
end
