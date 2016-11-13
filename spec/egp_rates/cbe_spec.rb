# frozen_string_literal: true
describe EGPRates::CBE do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 9
    expect(bank.exchange_rates[:sell].size).to eq 9
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :CBE
      expect(bank.instance_variable_get(:@uri)).to be_a URI
    end
  end

  describe '#exchange_rates' do
    it 'calls #parse with #raw_exchange_rates' do
      expect(bank).to receive(:raw_exchange_rates)
      expect(bank).to receive(:parse)
      bank.exchange_rates
    end
  end

  describe '#raw_exchange_rates' do
    it 'raises ResponseError unless Net::HTTPSuccess', :no_vcr do
      stub_request(:get, /.*cbe.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*cbe.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 9 rows', vcr: { cassette_name: :CBE } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 9
    end
  end

  describe '#currency_symbol' do
    %w(US Euro Sterling Swiss Japanese Saudi Kuwait UAE Chinese)\
      .each do |currency|
      it "returns currency :SYM for #{currency}" do
        symbols = %i(USD EUR GBP CHF JPY SAR KWD AED CNY)
        expect(symbols).to include(bank.send(:currency_symbol, currency))
      end
    end

    it 'raises ResponseError when Unknown Currency' do
      expect { bank.send(:currency_symbol, 'Egyptian pound') }.to raise_error\
        EGPRates::ResponseError, 'Unknown currency Egyptian pound'
    end
  end

  describe '#parse', vcr: { cassette_name: :CBE } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to include(
        AED: 4.6524,
        CHF: 17.3096,
        CNY: 2.5138,
        EUR: 18.6155,
        GBP: 21.2365,
        JPY: 16.0014,
        KWD: 56.3718,
        SAR: 4.5562,
        USD: 17.0863
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to include(
        AED: 4.4518,
        CHF: 16.551,
        CNY: 2.4052,
        EUR: 17.8111,
        GBP: 20.3231,
        JPY: 15.3113,
        KWD: 53.8492,
        SAR: 4.3603,
        USD: 16.354
      )
    end
  end
end
