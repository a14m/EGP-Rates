# frozen_string_literal: true
module EGPRates
  # Faisal Islamic Bank of Egypt
  class FaisalBank < EGPRates::Bank
    def initialize
      @sym = :FaisalBank
      @uri = URI.parse('https://online.faisalbank.com.eg/IB/.FIBUserServices/currencyXRate.do?op=getCurrencyExchangeRates&LangID=2')
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
    #     ["", "USD", "", "17.2500", "", "17.7500", ...]
    #     ["", "SAR", "", "4.5745", "", "4.7849" ... ]
    #     ...
    #   ]
    def raw_exchange_rates
      table_rows = Oga.parse_html(response.body).css('.Action-Table td')
      # each  currency of the 13 provided in 5 table data
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 13 * 5
      table_rows.map(&:text).map(&:strip).each_slice(5)
    end
  end
end
