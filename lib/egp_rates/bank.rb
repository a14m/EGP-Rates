# frozen_string_literal: true
module EGPRates
  # Class Representing the bank to get the data from
  class Bank
    attr_reader :sym

    # Abstract method
    # Subclasses banks define the logic to get the exchange rates hash
    # it should return [Hash] sell: { SYM: rate, ... } , buy: { SYM: rate, ... }
    #   for the available currencies (represented by :SYM) on the bank pages
    def exchange_rates
      raise NotImplementedError
    end

    private

    # Make a call to the @uri to get the raw_response
    # @return [Net::HTTPSuccess] of the raw response
    # @raises [ResponseError] if response is not 200 OK
    def response
      response = Net::HTTP.get_response(@uri)
      fail ResponseError, response.code unless response.is_a? Net::HTTPSuccess
      response
    end

    # Parse the #raw_exchange_rates returned in response
    # @param [Array] of the raw_data scraped
    #   [
    #     [ 'Currency_1', 'BuyRate', 'SellRate', ... ],
    #     [ 'Currency_2', 'BuyRate', 'SellRate', ... ],
    #     [ 'Currency_3', 'BuyRate', 'SellRate', ... ],
    #     ...
    #   ]
    #
    # @return [Hash] of exchange rates for selling and buying
    #   {
    #     { sell: { SYM: rate }, { SYM: rate }, ... },
    #     { buy:  { SYM: rate }, { SYM: rate }, ... }
    #   }
    def parse(raw_data)
      raw_data.each_with_object(sell: {}, buy: {}) do |row, result|
        sell_rate = row[2].to_f
        buy_rate  = row[1].to_f
        currency  = currency_symbol(row[0])

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
