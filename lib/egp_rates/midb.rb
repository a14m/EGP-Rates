# frozen_string_literal: true
module EGPRates
  # Misr Iran Development Bank (MIDB)
  class MIDB < EGPRates::Bank
    def initialize
      @sym = :MIDB
      @uri = URI.parse('http://www.midb.com.eg/currency.aspx')
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
    #       "\r\n\t", "USD", "17.5", "17.05", "17.5", "17.05", "\r\n\t\t"
    #     ], [
    #       "\r\n\t", "GBP", "21.6866", "21.0027", "21.6866", "21.0027", ...
    #     ]
    #     ...
    #   ]
    def raw_exchange_rates
      table_rows = Oga.parse_html(response.body)
                      .css('#MainContent_grdcurrency tr')
      # MIDB porvide 7 currencies on the home page but with header
      # and an empty row in the end
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 8
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
        sell_rate = row[2].to_f
        buy_rate  = row[3].to_f
        currency  = row[1].to_sym

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
