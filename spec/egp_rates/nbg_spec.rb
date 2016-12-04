# frozen_string_literal: true
describe EGPRates::NBG do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 9
    expect(bank.exchange_rates[:sell].size).to eq 9
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :NBG
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
      stub_request(:get, /.*nbg.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*nbg.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 9 rows', vcr: { cassette_name: :NBG } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 9
    end
  end

  describe '#parse', vcr: { cassette_name: :NBG } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        CAD: 13.7348,
        CHF: 18.0735,
        DKK: 2.6155,
        EUR: 19.454,
        GBP: 23.1813,
        JPY: 16.065,
        SAR: 4.8536,
        SEK: 1.983,
        USD: 18.2
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        CAD: 13.1381,
        CHF: 17.2891,
        DKK: 2.4995,
        EUR: 18.5903,
        GBP: 21.9888,
        JPY: 15.3227,
        SAR: 4.666,
        SEK: 1.8968,
        USD: 17.5
      )
    end
  end
end
