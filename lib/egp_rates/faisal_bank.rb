# frozen_string_literal: true
module EGPRates
  # Faisal Islamic Bank of Egypt
  class FaisalBank < EGPRates::Bank
    def initialize
      @sym = :FaisalBank
      @uri = URI.parse('http://www.faisalbank.com.eg/FIB/arabic/rate.html')
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
    #     ["", "USD", "", "17.2500", "", "17.7500", ...]
    #     ["", "SAR", "", "4.5745", "", "4.7849" ... ]
    #     ...
    #   ]
    def raw_exchange_rates
      table_rows = Oga.parse_html(response.body).css('.even')
      # FaisalBank porvide 13 currencies
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 13
      table_rows.lazy.map(&:children).map do |cell|
        cell.to_a.drop(2).map(&:text).map(&:strip)
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
        sell_rate = row[5].to_f
        buy_rate  = row[3].to_f
        currency  = row[1].to_sym

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
