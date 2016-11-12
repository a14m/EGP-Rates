# frozen_string_literal: true
describe EGPRates::NBE do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 17
    expect(bank.exchange_rates[:sell].size).to eq 17
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :NBE
      expect(bank.instance_variable_get(:@uri)).to be_a URI
    end
  end

  describe '#exchange_rates', vcr: { cassette_name: :NBE } do
    it 'calls #parse with #raw_exchange_rates' do
      expect(bank).to receive(:raw_exchange_rates)
      expect(bank).to receive(:parse)
      bank.exchange_rates
    end
  end

  describe '#raw_exchange_rates' do
    it 'raises ResponseError unless Net::HTTPSuccess', :no_vcr do
      stub_request(:get, /.*nbe.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*nbe.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 17 rows', vcr: { cassette_name: :NBE } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 17
    end
  end

  describe '#parse', vcr: { cassette_name: :NBE } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to include(
        AED: 4.3697,
        AUD: 12.2445,
        BAD: 42.5854,
        CAD: 11.9278,
        CHF: 16.3259,
        DKK: 2.3557,
        EUR: 17.5314,
        GBP: 20.3402,
        JOD: 22.6567,
        JPY: 15.1358,
        NOK: 1.9223,
        KWD: 53.0228,
        OMR: 41.6991,
        QTR: 4.4084,
        SAR: 4.2794,
        SEK: 1.7786,
        USD: 16.05
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to include(
        AED: 4.3288,
        AUD: 11.9663,
        BAD: 42.1538,
        CAD: 11.7369,
        CHF: 16.0687,
        DKK: 2.3138,
        EUR: 17.2213,
        GBP: 19.9179,
        JOD: 22.4354,
        JPY: 14.8695,
        KWD: 52.3715,
        NOK: 1.8842,
        OMR: 41.2612,
        QTR: 4.3665,
        SAR: 4.2393,
        SEK: 1.7447,
        USD: 15.9
      )
    end
  end
end
