# frozen_string_literal: true
describe EGPRates::MIDB do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 7
    expect(bank.exchange_rates[:sell].size).to eq 7
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :MIDB
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
      stub_request(:get, /.*midb.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*midb.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 7 rows', vcr: { cassette_name: :MIDB } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 7
    end
  end

  describe '#parse', vcr: { cassette_name: :MIDB } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 4.934,
        CHF: 17.925,
        EUR: 19.3346,
        GBP: 23.0696,
        JPY: 15.9611,
        SAR: 4.8322,
        USD: 18.05
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.7094,
        CHF: 17.423,
        EUR: 18.7931,
        GBP: 22.4235,
        JPY: 15.5141,
        SAR: 4.6122,
        USD: 17.65
      )
    end
  end
end
