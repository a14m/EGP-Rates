# frozen_string_literal: true
module EGPRates
  # Bank of Alexandria
  class AlexBank < EGPRates::Bank
    def initialize
      @sym = :AlexBank
      @uri = URI.parse('https://www.alexbank.com/En/Home/ExchangeRates')
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
    #   ["", "US Dollar", "", ..., "17.10000", "", "17.50000", ""]
    #   ["", "British Pound", "", ..., "21.12363", "", "21.60025", ""]
    #   ...
    #
    def raw_exchange_rates
      # AlexBank provide 17 currencies (and 1 <th>)
      table_rows = Oga.parse_html(response.body).css('.exchangerate-table tr')
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 18
      table_rows.lazy.drop(1).map(&:children).map do |cell|
        cell.map(&:text).map(&:strip)
      end
    end

    # Convert currency string to ISO symbol
    # @param currency [String] "US Dollar"
    # @return [Symbol] :USD ISO currency name
    # rubocop:disable Metrics/CyclomaticComplexity
    def currency_symbol(currency)
      case currency
      when /UAE Dirham/ then :AED
      when /Australian/ then :AUD
      when /Bahraini/   then :BHD
      when /Canadian/   then :CAD
      when /Swiss/      then :CHF
      when /Danish/     then :DKK
      when /Euro/       then :EUR
      when /British/    then :GBP
      when /Jordanian/  then :JOD
      when /Japanese/   then :JPY
      when /Kuwaiti/    then :KWD
      when /Norwegian/  then :NOK
      when /Omani/      then :OMR
      when /Qatari/     then :QAR
      when /Saudi/      then :SAR
      when /Swidish/    then :SEK
      when /US Dollar/  then :USD
      else fail ResponseError, "Unknown currency #{currency}"
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

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
        currency  = currency_symbol(row[1])

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
