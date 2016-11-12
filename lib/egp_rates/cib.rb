# frozen_string_literal: true
module EGPRates
  # National Bank of Egypt
  class CIB < EGPRates::Bank
    def initialize
      @sym = :CIB
      @uri = URI.parse('http://www.cibeg.com/_layouts/15/LINKDev.CIB.CurrenciesFunds/FundsCurrencies.aspx/GetCurrencies')
    end

    # @return [Hash] of exchange rates for selling and buying
    #   {
    #     { sell: { SYM: rate }, { SYM: rate }, ... },
    #     { buy:  { SYM: rate }, { SYM: rate }, ... }
    #   }
    def exchange_rates
      @exchange_rates ||= parse(raw_exchange_rates)
    end

    private

    # Send the request to URL and return the JSON response
    # @return [Hash] JSON response of the exchange rates
    #   {
    #     "d"=> [
    #       {
    #         "__type"=>"LINKDev.CIB.CurrenciesFunds.CIBFund.CurrencyObject",
    #         "CurrencyID"=>"USD",
    #         "BuyRate"=>15.9,
    #         "SellRate"=>16.05
    #       }, {
    #         "__type"=>"LINKDev.CIB.CurrenciesFunds.CIBFund.CurrencyObject",
    #         "CurrencyID"=>"EUR",
    #         "BuyRate"=>17.1904,
    #         "SellRate"=>17.5234
    #       }, {
    #         ...
    #       }
    #     ]
    #   }
    def raw_exchange_rates
      req = Net::HTTP::Post.new(@uri, 'Content-Type' => 'application/json')
      req.body = { lang: :en }.to_json
      response = Net::HTTP.start(@uri.hostname, @uri.port) do |http|
        http.request(req)
      end
      fail ResponseError, response.code unless response.is_a? Net::HTTPSuccess

      response = JSON.parse(response.body)

      # CIB provide 6 currencies only
      unless response['d'] && response['d'].size >= 6
        fail ResponseError, "Unknown JSON #{response}"
      end

      response
    rescue JSON::ParserError
      raise ResponseError, "Unknown JSON: #{response.body}"
    end

    # Parse the #raw_exchange_rates returned in response
    # @return [Hash] of exchange rates for selling and buying
    #   {
    #     { sell: { SYM: rate }, { SYM: rate }, ... },
    #     { buy:  { SYM: rate }, { SYM: rate }, ... }
    #   }
    def parse(raw_data)
      raw_data['d'].each_with_object(sell: {}, buy: {}) do |obj, result|
        sell_rate = obj['SellRate']
        buy_rate  = obj['BuyRate']
        currency  = obj['CurrencyID'].to_sym

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
