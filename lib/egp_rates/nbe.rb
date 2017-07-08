# frozen_string_literal: true
module EGPRates
  # National Bank of Egypt
  class NBE < EGPRates::Bank
    def initialize
      @sym = :NBE
      @uri = URI.parse('http://www.nbe.com.eg/en/ExchangeRate.aspx')
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
    #     "\r\n\t\t",
    #     "US DOLLAR",
    #     "USD       ",
    #     "\r\n\t\t\t\t\t\t\t\t\t15.9\r\n\t\t\t\t\t\t\t\t",
    #     "\r\n\t\t\t\t\t\t\t\t\t16.05\r\n\t\t\t\t\t\t\t\t",
    #     "\r\n\t\t\t\t\t\t\t\t\t15.9\r\n\t\t\t\t\t\t\t\t",
    #     "\r\n\t\t\t\t\t\t\t\t\t16.05\r\n\t\t\t\t\t\t\t\t",
    #     "\r\n\t"
    #   ], [
    #     "\r\n\t\t",
    #     "EURO",
    #     "EUR       ",
    #     "\r\n\t\t\t\t\t\t\t\t\t17.2213\r\n\t\t\t\t\t\t\t\t",
    #     "\r\n\t\t\t\t\t\t\t\t\t17.5314\r\n\t\t\t\t\t\t\t\t",
    #     "\r\n\t\t\t\t\t\t\t\t\t17.2213\r\n\t\t\t\t\t\t\t\t",
    #     "\r\n\t\t\t\t\t\t\t\t\t17.5314\r\n\t\t\t\t\t\t\t\t",
    #     "\r\n\t"
    #   ], [
    #     ...
    #   ]
    def raw_exchange_rates
      table_rows = Oga.parse_html(response.body).css('#idts_content tr')
      # NBE provide 17 currencies only
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 18
      # Drop 1 remove the table headers
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
        sell_rate = row[4].strip.to_f
        buy_rate  = row[3].strip.to_f
        # Bahraini Dinar is BHD not BAD
        # Changing it for consistency
        row[2].strip == 'BAD' ? currency = :BHD : currency = row[2].strip.to_sym

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
