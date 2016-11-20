# frozen_string_literal: true
module EGPRates
  # Société Arabe Internationale de Banque (SAIB)
  class SAIB < EGPRates::Bank
    def initialize
      @sym = :SAIB
      @uri = URI.parse('http://www.saib.com.eg/foreign-currencies/')
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
    #       "\n", "USD", "\n", "1605.00", "\n", "1675.00", "\n"
    #     ], [
    #       \n", "\xC2\xA0EUR", "\n", "1698", "\n", "1773", "\n
    #     ]
    #     ...
    #   ]
    #
    def raw_exchange_rates
      table_rows = Oga.parse_html(response.body).css('.cont table tbody tr')
      # SAIB porvide 6 currencies on the home page but with header
      # and an empty row in the end
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 8
      table_rows.lazy.drop(1).take(6).map(&:children).map do |cell|
        cell.map(&:text)
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
        sell_rate = (row[5].to_f / 100).round(4)
        buy_rate  = (row[3].to_f / 100).round(4)
        currency  = row[1].gsub(/\xC2\xA0/n, '').to_sym

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
