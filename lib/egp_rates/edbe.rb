# frozen_string_literal: true
module EGPRates
  # Export Development Bank of Egypt (EDBE)
  class EDBE < EGPRates::Bank
    def initialize
      @sym = :EDBE
      @uri = URI.parse('http://www.edbebank.com/EN/BankingServices/TreasuryFiles/exchangerates.xml')
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
    # @return [Array<Oga::XML::Attribute>]
    #   [
    #     Attribute(name: "USDBbuy" value: "17.2500"),
    #     Attribute(name: "USDBsell" value: "17.7000"),
    #     Attribute(name: "USDTbuy" value: "17.2500"),
    #     Attribute(name: "USDTsell" value: "17.6000"),
    #     ...
    #   ]
    def raw_exchange_rates
      response = Net::HTTP.get_response(@uri)
      fail ResponseError, response.code unless response.is_a? Net::HTTPSuccess
      table_rows = Oga.parse_xml(response.body).xpath('Details/rates')
      # EDBE porvide 5 as 20 XML attributes
      fail ResponseError, 'Unknown HTML' unless table_rows&.size == 1
      table_rows.flat_map(&:attributes).take(20)
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
        next unless row.name[3] == 'B'
        currency    = row.name[0..2].to_sym
        action      = row.name[4..-1].to_sym
        action_rate = row.value.to_f
        action_rate = (action_rate * 100).round(4) if currency == :JPY

        result[action][currency] = action_rate
      end
    end
  end
end
