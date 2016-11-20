# frozen_string_literal: true
module EGPRates
  # Crédit Agricole Egypt (CAE)
  class CAE < EGPRates::Bank
    def initialize
      @sym = :CAE
      @uri = URI.parse('https://www.ca-egypt.com/en/personal-banking/')
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
    #     ["QAR", "4.7367", "4.9294"],
    #     ["USD", "17.25", "17.95"]
    #     ...
    #   ]
    def raw_exchange_rates
      table_rows = Oga.parse_html(response.body).css('#f_box option')
      # CAE porvide 17 currencies on the home page but with header
      # and an empty row in the end
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 17
      table_rows.lazy.map do |row|
        [
          row.text,
          row.attribute('data-buy').value,
          row.attribute('data-sell').value
        ]
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
        sell_rate = row[2].to_f
        buy_rate  = row[1].to_f
        currency  = row[0].to_sym

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
