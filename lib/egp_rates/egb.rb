# frozen_string_literal: true
module EGPRates
  # Egyptian Gulf Bank (EGB)
  class EGB < EGPRates::Bank
    def initialize
      @sym = :EGB
      @uri = URI.parse('https://eg-bank.com/ExchangeRates/ExchangeRates/')
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
    #     ["", "USD", "", "17.00", "", "17.75", ""],
    #     ["", "EUR", "", "17.9639", "", "18.8896", ""],
    #     ["", "GBP", "", "20.9049", "", "22.0739", ""],
    #     ...
    #   ]
    def raw_exchange_rates
      table_rows = Oga.parse_html(response.body).css('.row.row-wrapper')
      # EGB porvide 17 currencies (and a header row)
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 18
      table_rows.lazy.drop(1).map(&:children).map do |cell|
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
        sell_rate = row[5].to_f
        buy_rate  = row[3].to_f
        currency  = row[1].to_sym

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
