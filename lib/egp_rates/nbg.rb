# frozen_string_literal: true
module EGPRates
  # National Bank of Greece (NBG)
  class NBG < EGPRates::Bank
    def initialize
      @sym = :NBG
      @uri = URI.parse('http://www.nbg.com.eg/en/exchange-rates')
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
    #     ["", "US Dollar", "", "USD", "", "17.2000", "", "17.8000", ...]
    #     ["", "Euro", "", "EUR", "", "18.1030", "", "18.3039", ... ]
    #     ...
    #   ]
    def raw_exchange_rates
      table_rows = Oga.parse_html(response.body).css('.row_exchange')
      # NBG porvide 9 currencies (and 2 header rows)
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 11
      table_rows.lazy.drop(2).map(&:children).map do |cell|
        cell.map(&:text).map(&:strip)
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
        sell_rate = row[7].to_f
        buy_rate  = row[5].to_f
        currency  = row[3].to_sym

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
