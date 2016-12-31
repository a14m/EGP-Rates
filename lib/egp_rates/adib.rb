# frozen_string_literal: true
module EGPRates
  # Abu Dhabi Islamic Bank (ADIB)
  class ADIB < EGPRates::Bank
    def initialize
      @sym = :ADIB
      @uri = URI.parse('https://www.adib.eg/')
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

    # Send the request to the URL and retrun raw data of the response
    # @return [Array<Array>] containing image url (currency) and exchange rates
    #   [
    #     ["/media/246206/usd.png", [["Buy: 18.1000", "Sell: 18.85"]]],
    #     ["/media/246211/gbp.png", [["Buy: 22.1019", "Sell: 23.1365"]]]
    #     ...
    #   ]
    def raw_exchange_rates
      table_rows = Oga.parse_html(response.body).css('#ratesContainer li')
      # ADIB porvide 5 currencies on the home page (and 4 rows of info)
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 5
      currencies(table_rows).zip(rates(table_rows))
    end


    # Extract the currencies from the image components src attribute
    # @return [Array<String>] containing the URL to image of the currency
    def currencies(table_rows)
      table_rows.lazy.map do |e|
        e.css('img').map { |img| img.attribute('src').value }
      end.force.flatten
    end

    # Extract the text descriping the exchange rates from content <p> nodes
    # @return [Array<Array>] text description for buy/sell rates
    def rates(table_rows)
      table_rows.map do |e|
        e.css('.content').map(&:text).map(&:strip).map do |txt|
          txt.split("\n").map(&:strip)
        end
      end
    end

    # Parse the #raw_exchange_rates returned in response
    # @param [Array] of the raw_data scraped
    # @return [Hash] of exchange rates for selling and buying
    #   {
    #     { sell: { SYM: rate }, { SYM: rate }, ... },
    #     { buy:  { SYM: rate }, { SYM: rate }, ... }
    #   }
    def parse(raw_data)
      raw_data.each_with_object(sell: {}, buy: {}) do |row, result|
        currency  = currency_symbol(row[0])
        sell_rate = row[1][0][1][5..-1].to_f
        buy_rate  = row[1][0][0][4..-1].to_f

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
