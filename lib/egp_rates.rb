# frozen_string_literal: true

require 'oga'
require 'json'
require 'uri'
require 'net/http'
require 'thread'
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
require 'egp_rates/midb'
require 'egp_rates/ube'
require 'egp_rates/cae'
require 'egp_rates/edbe'
require 'egp_rates/alex_bank'
require 'egp_rates/blom'
require 'egp_rates/adib'
require 'egp_rates/egb'
require 'egp_rates/nbg'

# Base Module
module EGPRates
  # Class Idicating HTTPResponseErrors when unexpected behaviour encountered
  # while scraping the [Bank] data
  class ResponseError < StandardError
  end

  # Threaded execution to get the exchange rates from different banks
  # @return [Hash] of the exchange rates of different banks
  #   {
  #     BANK: {
  #       sell: { SYM: rate, SYM: rate },
  #       buy:  { SYM: rate, SYM: rate }
  #     },
  #     BANK: {
  #       sell: { SYM: rate, SYM: rate },
  #       buy:  { SYM: rate, SYM: rate }
  #     },
  #   }
  def self.exchange_rates
    semaphore = Mutex.new
    # Fetch all the constants (Banks) implemented
    (constants - [:Bank, :ResponseError]).each_with_object({}) do |klass, rates|
      Thread.new do
        bank = EGPRates.const_get(klass).new

        semaphore.synchronize do
          begin
            rates[klass] = bank.exchange_rates
          rescue ResponseError
            rates[klass] = 'Failed to get exchange rates'
          end
        end
      end.join
    end
  end

  # Return the exchange rate of a single currency from different banks
  # @param [Symbol] sym, 3 charachter ISO symbol of the currency
  # @param [Boolean] cache_result, a boolean to indicate whether or not
  #   the result of the exchange_rates call be cached
  # @return [Hash] of the exchange rates in different banks for a specific
  #   currency
  def self.exchange_rate(sym = :USD, cache_result = true)
    @exchange_rates ||= exchange_rates if cache_result
    @exchange_rates   = exchange_rates unless cache_result

    @exchange_rates.each_with_object({}) do |rates, result|
      begin
        result[rates[0]] = {
          sell: rates[1][:sell].fetch(sym.upcase, 'N/A'),
          buy:  rates[1][:buy].fetch(sym.upcase,  'N/A')
        }
      rescue TypeError
        result[rates[0]] = rates[1]
      end
    end
  end
end
