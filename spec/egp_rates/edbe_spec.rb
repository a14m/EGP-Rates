# frozen_string_literal: true
describe EGPRates::EDBE do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 5
    expect(bank.exchange_rates[:sell].size).to eq 5
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :EDBE
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
      stub_request(:get, /.*edbebank.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*edbebank.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Array> of 20 values', vcr: { cassette_name: :EDBE } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Array
      expect(lazy_enumerator.size).to eq 20
    end
  end

  describe '#parse', vcr: { cassette_name: :EDBE } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        CHF: 17.8749,
        EUR: 19.2402,
        GBP: 22.9266,
        JPY: 15.8884,
        USD: 18.0
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        CHF: 17.5064,
        EUR: 18.824,
        GBP: 22.2652,
        JPY: 15.5153,
        USD: 17.72
      )
    end
  end
end
