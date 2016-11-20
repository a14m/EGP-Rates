# frozen_string_literal: true

require 'oga'
require 'json'
require 'egp_rates/bank'
require 'egp_rates/cbe'
require 'egp_rates/nbe'
require 'egp_rates/cib'
require 'egp_rates/aaib'
require 'egp_rates/banque_misr'
require 'egp_rates/banque_du_caire'
require 'egp_rates/suez_canal_bank'
require 'egp_rates/al_baraka_bank'
require 'egp_rates/al_ahli_bank_of_kuwait'
require 'egp_rates/saib'
require 'egp_rates/midb'
require 'egp_rates/ube'
require 'egp_rates/cae'
require 'egp_rates/edbe'
require 'egp_rates/alex_bank'
require 'egp_rates/blom'
require 'egp_rates/adib'
require 'egp_rates/egb'

# Base Module
module EGPRates
  # Class Idicating HTTPResponseErrors when unexpected behaviour encountered
  # while scraping the [Bank] data
  class ResponseError < StandardError
  end
end
