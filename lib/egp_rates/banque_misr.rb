# frozen_string_literal: true
module EGPRates
  # Banque Misr
  class BanqueMisr < EGPRates::Bank
    def initialize
      @sym = :BanqueMisr
      @uri = URI.parse('http://www.banquemisr.com/en/exchangerates')
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
    #     ["US DOLLAR", "15.35", "15.91", "15.35", "15.91"],
    #     ["EURO", "16.6256", "17.3698", "16.633898", "17.378493"]
    #     ...
    #   ]
    #
    def raw_exchange_rates
      # BanqueMisr provide 18 currencies (17 Used and CYPRUS POUND)
      # But they have 2 <tr> for headers
      table_rows = Oga.parse_html(response.body).css('.exchangeRates tbody tr')
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 20
      # remove the first 2 headers of the array and the last element
      # which is CYPRUS POUND which is not used anymore
      table_rows.lazy.drop(2).take(17).map(&:children).map do |cell|
        cell.map(&:text)
      end
    end

    # Convert currency string to ISO symbol
    # @param currency [String] "US Dollar"
    # @return [Symbol] :USD ISO currency name
    # rubocop:disable Metrics/CyclomaticComplexity
    def currency_symbol(currency)
      case currency
      when /UAE DIRHAM/ then :AED
      when /AUSTRALIA/  then :AUD
      when /BAHRAIN/    then :BHD
      when /CANADA/     then :CAD
      when /SWEDISH/    then :CHF
      when /DENMARK/    then :DKK
      when /EURO/       then :EUR
      when /GB POUND/   then :GBP
      when /JORDANIAN/  then :JOD
      when /JAPAN/      then :JPY
      when /KUWAIT/     then :KWD
      when /NORWAY/     then :NOK
      when /OMAN/       then :OMR
      when /QATARI/     then :QAR
      when /SAUDI/      then :SAR
      when /SWISS/      then :SEK
      when /US DOLLAR/  then :USD
      else fail ResponseError, "Unknown currency #{currency}"
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end
