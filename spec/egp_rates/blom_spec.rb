# frozen_string_literal: true
describe EGPRates::Blom do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 14
    expect(bank.exchange_rates[:sell].size).to eq 14
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :Blom
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
      stub_request(:get, /.*blom.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*blom.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 14 rows',
       vcr: { cassette_name: :Blom } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 14
    end
  end

  describe '#parse', vcr: { cassette_name: :Blom } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 4.9006,
        BHD: 0.0,
        CAD: 13.5788,
        CHF: 17.8625,
        DKK: 2.5862,
        EUR: 19.2402,
        GBP: 22.9266,
        JPY: 15.88,
        KWD: 59.0164,
        NOK: 2.143,
        QAR: 0.0,
        SAR: 4.7992,
        SEK: 1.9644,
        USD: 18.0
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.7781,
        BHD: 0.0,
        CAD: 13.1757,
        CHF: 17.3385,
        DKK: 2.5066,
        EUR: 18.6486,
        GBP: 22.0621,
        JPY: 15.3664,
        KWD: 57.541,
        NOK: 2.0741,
        QAR: 0.0,
        SAR: 4.6788,
        SEK: 1.9022,
        USD: 17.55
      )
    end
  end
end
