# frozen_string_literal: true
module EGPRates
  # Blom Bank Egypt
  class Blom < EGPRates::Bank
    def initialize
      @sym = :Blom
      @uri = URI.parse('http://www.blombankegypt.com/BlomEgypt/Exchange-rates')
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
    # @return [Enumerator::Lazy] with the table row in HTML that evaluates to
    #   [
    #     ["", "USD   02", "", "", "", ..., "17.0000", "", "17.7500", ""]
    #     ["", "EURO  30", "", "", "", ..., "17.9690", "", "18.8896", ""]
    #     ...
    #   ]
    def raw_exchange_rates
      table_rows = Oga.parse_html(response.body).css('.tableHolder').first
      table_rows = table_rows&.css('tr')
      # Blom porvide 14 currencies on the home page (and 2 <th>)
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 16
      table_rows.lazy.drop(2).map(&:children).map do |row|
        row.map(&:text).map(&:strip)
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
        sell_rate = row[11].to_f
        buy_rate  = row[9].to_f
        currency  = row[1][0..2].to_sym
        currency  = :JPY if currency == '100'.to_sym

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
