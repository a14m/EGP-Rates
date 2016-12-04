# frozen_string_literal: true
describe EGPRates::AlBarakaBank do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 7
    expect(bank.exchange_rates[:sell].size).to eq 7
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :AlBarakaBank
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
      stub_request(:get, /.*albaraka.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*albaraka.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 7 rows',
       vcr: { cassette_name: :AlBarakaBank } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 7
    end
  end

  describe '#currency_symbol' do
    %w(USD EURO GBP CHF JPY SAR BHD)\
      .each do |currency|
      it "returns currency :SYM for #{currency}" do
        symbols = %i(USD EUR GBP CHF JPY SAR BHD)
        expect(symbols).to include(bank.send(:currency_symbol, currency))
      end
    end

    it 'raises ResponseError when Unknown Currency' do
      expect { bank.send(:currency_symbol, 'Egyptian pound') }.to raise_error\
        EGPRates::ResponseError, 'Unknown currency Egyptian pound'
    end
  end

  describe '#parse', vcr: { cassette_name: :AlBarakaBank } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        BHD: 48.3615,
        CHF: 18.4535,
        EUR: 19.4932,
        GBP: 23.2589,
        JPY: 16.0489,
        SAR: 4.8618,
        USD: 18.09
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        BHD: 46.3908,
        CHF: 17.2842,
        EUR: 18.6618,
        GBP: 22.2669,
        JPY: 15.3949,
        SAR: 4.588,
        USD: 17.74
      )
    end
  end
end
