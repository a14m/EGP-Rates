# frozen_string_literal: true
module EGPRates
  # Central Bank of Egypt
  class CBE < EGPRates::Bank
    def initialize
      @sym = :CBE
      @uri = URI.parse('http://www.cbe.org.eg/en/EconomicResearch/Statistics/Pages/ExchangeRatesListing.aspx')
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
    #     "US Dollar \r\n  ", "15.7297", "16.3929",
    #     "Euro \r\n,      ", "17.5308", "18.1938",
    #     ...
    #   ]
    #
    def raw_exchange_rates
      response = Net::HTTP.get_response(@uri)
      fail ResponseError, response.code unless response.is_a? Net::HTTPSuccess
      table_rows = Oga.parse_html(response.body).css('tbody').last&.children
      # CBE porvide 9 currencies on the home page
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 9
      table_rows.lazy.map(&:children).map { |cell| cell.map(&:text) }
    end

    # Convert currency string to ISO symbol
    # @param currency [String] "US Dollar"
    # @return [Symbol] :USD ISO currency name
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    def currency_symbol(currency)
      case currency
      when /US/        then :USD
      when /Euro/      then :EUR
      when /Sterling/  then :GBP
      when /Swiss/     then :CHF
      when /Japanese/  then :JPY
      when /Saudi/     then :SAR
      when /Kuwait/    then :KWD
      when /UAE/       then :AED
      when /Chinese/   then :CNY
      else fail ResponseError, "Unknown currency #{currency}"
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    # Parse the #raw_exchange_rates returned in response
    # @return [Hash] of exchange rates for selling and buying
    #   {
    #     { sell: { SYM: rate }, { SYM: rate }, ... },
    #     { buy:  { SYM: rate }, { SYM: rate }, ... }
    #   }
    def parse(raw_data)
      raw_data.each_with_object(sell: {}, buy: {}) do |row, result|
        sell_rate = row[2].to_f
        buy_rate  = row[1].to_f
        currency  = currency_symbol(row[0])

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
