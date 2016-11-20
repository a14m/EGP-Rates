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
    # @return [Enumerator::Lazy] with the table row in HTML that evaluates to
    #   [
    #     ["\n", "USD", "\n", "17.0000", "\n", "17.5000", "\n"],
    #     ["\n", "GBP", "\n", "20.9049", "\n", "21.7630", "\n"],
    #     ...
    #   ]
    def raw_exchange_rates
      table_rows = Oga.parse_html(response.body).css('.CallUs tbody tr')
      # ADIB porvide 5 currencies on the home page (and 4 rows of info)
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 9
      table_rows.lazy.drop(4).map(&:children).map { |cell| cell.map(&:text) }
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
