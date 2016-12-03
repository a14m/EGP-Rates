# frozen_string_literal: true
module EGPRates
  # Al Ahli Bank Of Kuwait
  class AlAhliBankOfKuwait < EGPRates::Bank
    def initialize
      @sym = :AlAhliBankOfKuwait
      @uri = URI.parse('http://www.abkegypt.com/rates_abk.aspx')
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
    #       "", "EUR", "", "17.094800", "", "17.528100", "", ...
    #     ], [
    #       "", "CHF", "", "15.983800", "", "16.395900", "", ...
    #     ]
    #     ...
    #   ]
    #
    def raw_exchange_rates
      table_rows = Oga.parse_html(response.body).css('.ORANGE_TEXT, .BLUE_TEXT')
      # AlAhliBankOfKuwait porvide 8 currencies on the home page
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 8
      table_rows.lazy.map(&:children).map do |cell|
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
        sell_rate = row[9].to_f
        buy_rate  = row[7].to_f
        currency  = row[1].to_sym

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
