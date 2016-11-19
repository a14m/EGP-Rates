# frozen_string_literal: true
module EGPRates
  # Central Bank of Egypt
  class AlBarakaBank < EGPRates::Bank
    def initialize
      @sym = :AlBarakaBank
      @uri = URI.parse('http://www.albaraka-bank.com.eg/banking-services/exchange-rates.aspx')
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
    #       "USD", "1596.00", "1650.00", ...
    #     ], [
    #       "GBP", "1953.06", "2079.83", ...
    #     ], [
    #       "EURO", "1672.32", "1787.11", ...
    #     ]
    #     ...
    #   ]
    #
    def raw_exchange_rates
      response = Net::HTTP.get_response(@uri)
      fail ResponseError, response.code unless response.is_a? Net::HTTPSuccess
      table_rows = Oga.parse_html(response.body).css('table').first&.children
      # AlBarakaBank porvide 7 currencies on the home page
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 8
      table_rows.lazy.drop(1).map(&:children).map { |cell| cell.map(&:text) }
    end

    # Convert currency string to ISO symbol
    # @param currency [String] "US Dollar"
    # @return [Symbol] :USD ISO currency name
    # rubocop:disable Metrics/CyclomaticComplexity
    def currency_symbol(currency)
      case currency
      when /USD/       then :USD
      when /EURO/      then :EUR
      when /GBP/       then :GBP
      when /CHF/       then :CHF
      when /JPY/       then :JPY
      when /SAR/       then :SAR
      when /BHD/       then :BHD
      else fail ResponseError, "Unknown currency #{currency}"
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # Parse the #raw_exchange_rates returned in response
    # @param [Array] of the raw_data scraped
    #   [
    #     [ 'Currency_1', 'BuyRate', 'SellRate', ... ],
    #     [ 'Currency_2', 'BuyRate', 'SellRate', ... ],
    #     [ 'Currency_3', 'BuyRate', 'SellRate', ... ],
    #     ...
    #   ]
    #
    # @return [Hash] of exchange rates for selling and buying
    #   {
    #     { sell: { SYM: rate }, { SYM: rate }, ... },
    #     { buy:  { SYM: rate }, { SYM: rate }, ... }
    #   }
    def parse(raw_data)
      raw_data.each_with_object(sell: {}, buy: {}) do |row, result|
        sell_rate = (row[2].to_f / 100).round(4)
        buy_rate  = (row[1].to_f / 100).round(4)
        currency  = currency_symbol(row[0])

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
