# frozen_string_literal: true
module EGPRates
  # Arab African International Bank
  class AAIB < EGPRates::Bank
    def initialize
      @sym = :AAIB
      @uri = URI.parse('http://aaib.com/services/rates')
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
    #       "\r\n ",
    #       "US DOLLAR"
    #       "\r\n "
    #       "15.9"
    #       "\r\n "
    #       "16.05"
    #       "\r\n"
    #     ], [
    #       "\r\n "
    #       "EURO CURRENCY"
    #       "\r\n "
    #       "17.2213"
    #       "\r\n "
    #       "17.5314"
    #       "\r\n "
    #     ], [
    #       ...
    #     ]
    def raw_exchange_rates
      raw = response.body&.gsub("\u0000", '')
      # AAIB provide 7 currencies only
      table_rows = Oga.parse_html(raw).css('#rates-table tr')
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 7
      table_rows.lazy.map(&:children).map { |cell| cell.map(&:text) }
    end

    # Convert currency string to ISO symbol
    # @param currency [String] "US Dollar"
    # @return [Symbol] :USD ISO currency name
    # rubocop:disable Metrics/CyclomaticComplexity
    def currency_symbol(currency)
      case currency
      when /US DOLLAR/ then :USD
      when /EURO/      then :EUR
      when /STERLING/  then :GBP
      when /SWISS/     then :CHF
      when /SAUDI/     then :SAR
      when /KUWAITI/   then :KWD
      when /DIRHAM/    then :AED
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
        sell_rate = row[5].to_f
        buy_rate  = row[3].to_f
        currency  = currency_symbol(row[1])

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
