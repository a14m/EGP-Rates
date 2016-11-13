
# frozen_string_literal: true
module EGPRates
  # Arab African International Bank
  class BanqueDuCaire < EGPRates::Bank
    def initialize
      @sym = :BanqueDuCaire
      @uri = URI.parse('http://www.banqueducaire.com/English/MarketUpdates/Pages/CurrencyExchange.aspx')
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
    #     ["US DOLLAR", "15.35", "16.25"],
    #     ["EURO", "16.6194", "17.7499"],
    #     ...
    #   ]
    #
    def raw_exchange_rates
      response = Net::HTTP.get_response(@uri)
      fail ResponseError, response.code unless response.is_a? Net::HTTPSuccess
      # Banque Du Caire provide 17 currencies only
      table_rows = Oga.parse_html(response.body).css('table.curTbl tr')
      # But they have 1 empty <tr> and 1 header <tr> elements
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 19
      table_rows.lazy.drop(2).map(&:children).map { |cell| cell.map(&:text) }
    end

    # Convert currency string to ISO symbol
    # @param currency [String] "US Dollar"
    # @return [Symbol] :USD ISO currency name
    # rubocop:disable Metrics/CyclomaticComplexity
    def currency_symbol(currency)
      case currency
      when /EMIRATES/   then :AED
      when /AUSTRALIAN/ then :AUD
      when /BAHRAIN/    then :BHD
      when /CANADIAN/   then :CAD
      when /SWISS/      then :CHF
      when /DANISH/     then :DKK
      when /EURO/       then :EUR
      when /BRITISH/    then :GBP
      when /JORDANIAN/  then :JOD
      when /JAPANESE/   then :JPY
      when /KUWAITI/    then :KWD
      when /NORWEGIAN/  then :NOK
      when /OMANI/      then :OMR
      when /QATAR/      then :QAR
      when /SAUDI/      then :SAR
      when /SWEDISH/    then :SEK
      when /US DOLLAR/  then :USD
      else fail ResponseError, "Unknown currency #{currency}"
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end
