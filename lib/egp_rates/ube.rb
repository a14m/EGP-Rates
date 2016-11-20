# frozen_string_literal: true
module EGPRates
  # Central Bank of Egypt
  class UBE < EGPRates::Bank
    def initialize
      @sym = :UBE
      @uri = URI.parse('http://www.theubeg.com/fxRate')
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
    #     [
    #       "\r", "U.S. Dollar", "\r", "USD", "\r", "17.28", "\r", "17.55", "\r"
    #     ], [
    #       "\r", "Euro", "\r", "EUR", "\r", "18.265", "\r", "18.6644", "\r"
    #     ]
    #     ...
    #   ]
    def raw_exchange_rates
      response = Net::HTTP.get_response(@uri)
      fail ResponseError, response.code unless response.is_a? Net::HTTPSuccess
      table_rows = Oga.parse_html(response.body).css('table tr')
      # UBE porvide 6 currencies on the home page but with header
      # and an empty row in the end
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 7
      table_rows.lazy.drop(1).map(&:children).map { |cell| cell.map(&:text) }
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
