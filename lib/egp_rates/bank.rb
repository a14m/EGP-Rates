# frozen_string_literal: true
# Class Representing the bank to get the data from
class Bank
  # Class Idicating HTTPResponseErrors when unexpected behaviour encountered
  # while scraping the [Bank] data
  class ResponseError < StandardError
  end

  attr_reader :sym

  # Abstract method
  # Subclasses banks define the logic to get the exchange rates hash
  # it should return [Hash] { { sell: { SYM: rate } }, { buy: { SYM: rate } } }
  #   for the available currencies (represented by :SYM) on the bank pages
  def exchange_rates
    raise NotImplementedError
  end
end
