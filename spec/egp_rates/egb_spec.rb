# frozen_string_literal: true
describe EGPRates::EGB do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 17
    expect(bank.exchange_rates[:sell].size).to eq 17
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :EGB
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
      stub_request(:get, /.*eg-bank.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*eg-bank.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 17 rows', vcr: { cassette_name: :EGB } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 17
    end
  end

  describe '#parse', vcr: { cassette_name: :EGB } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 4.9421,
        AUD: 13.5544,
        BHD: 48.156,
        CAD: 13.6971,
        CHF: 18.0238,
        DKK: 2.6084,
        EUR: 19.4005,
        GBP: 23.1177,
        JOD: 25.6356,
        JPY: 0.1602,
        KWD: 59.5472,
        NOK: 2.1634,
        OMR: 47.1551,
        QAR: 4.9853,
        SAR: 4.8394,
        SEK: 1.9775,
        USD: 18.15
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.7917,
        AUD: 13.0152,
        BHD: 46.6844,
        CAD: 13.2132,
        CHF: 17.3879,
        DKK: 2.5137,
        EUR: 18.6965,
        GBP: 22.1144,
        JOD: 24.7887,
        JPY: 0.1541,
        KWD: 57.7049,
        NOK: 2.08,
        OMR: 45.7143,
        QAR: 4.8329,
        SAR: 4.6926,
        SEK: 1.9077,
        USD: 17.6
      )
    end
  end
end
