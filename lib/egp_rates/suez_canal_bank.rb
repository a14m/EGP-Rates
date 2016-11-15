# frozen_string_literal: true
module EGPRates
  # Suez Canal Bank
  class SuezCanalBank < EGPRates::Bank
    def initialize
      @sym = :SuezCanalBank
      @uri = URI.parse('http://scbank.com.eg/CurrencyAll.aspx')
    end

    # @return [Hash] of exchange rates for selling and buying
    #   {
    #     { sell: { SYM: rate }, { SYM: rate }, ... },
    #     { buy:  { SYM: rate }, { SYM: rate }, ... }
    #   }
    def exchange_rates
      @exchange_rates ||= parse(raw_exchange_rates)
    end


    # Send the request to the URL and retrun raw data of the response
    # @return [Enumerator::Lazy] with the table row in HTML that evaluates to
    #   [
    #     "\r\n ",  "\r\n ", "\r\n ", "\r\n US Dollar ", "\r\n ",
    #     "\r\n 15.1500", "\r\n ", "\r\n 15.8000", "\r\n ", ...
    #   ], [
    #     "\r\n ", "\r\n ", "\r\n ", "\r\n Sterling Pound", "\r\n ",
    #     "\r\n 18.5933", "\r\n ", "\r\n 20.0448", "\r\n ", ...
    #   ],
    def raw_exchange_rates
      response = Net::HTTP.get_response(@uri)
      fail ResponseError, response.code unless response.is_a? Net::HTTPSuccess
      # Suez Canal Bank provides 13 currencies only
      table_rows = Oga.parse_html(response.body)\
        .css('#Table_01 tr:nth-child(4) > td:nth-child(2) > table tr')
      # But they have 2 <tr> used for the table headers
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 15
      table_rows.lazy.drop(2).map(&:children).map { |cell| cell.map(&:text) }
    end

    # Convert currency string to ISO symbol
    # @param currency [String] "US Dollar"
    # @return [Symbol] :USD ISO currency name
    # rubocop:disable Metrics/CyclomaticComplexity
    def currency_symbol(currency)
      case currency
      when /UAE Dirham/ then :AED
      when /Australian/ then :AUD
      when /Canadian/   then :CAD
      when /Swiss/      then :CHF
      when /Danish/     then :DKK
      when /EUR/        then :EUR
      when /Sterling/   then :GBP
      when /YEN/        then :JPY
      when /Kuwaiti/    then :KWD
      when /Norwegian/  then :NOK
      when /Saudi/      then :SAR
      when /Swedish/    then :SEK
      when /US Dollar/  then :USD
      else fail ResponseError, "Unknown currency #{currency}"
      end
    end

    # Parse the #raw_exchange_rates returned in response
    # @return [Hash] of exchange rates for selling and buying
    #   {
    #     { sell: { SYM: rate }, { SYM: rate }, ... },
    #     { buy:  { SYM: rate }, { SYM: rate }, ... }
    #   }
    def parse(raw_data)
      raw_data.each_with_object(sell: {}, buy: {}) do |row, result|
        sell_rate = row[7].to_f
        buy_rate  = row[5].to_f
        currency  = currency_symbol(row[3].strip)

        result[:sell][currency] = sell_rate
        result[:buy][currency]  = buy_rate
      end
    end
  end
end
