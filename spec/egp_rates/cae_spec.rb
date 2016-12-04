# frozen_string_literal: true
describe EGPRates::CAE do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 17
    expect(bank.exchange_rates[:sell].size).to eq 17
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :CAE
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
      stub_request(:get, /.*ca-egypt.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*ca-egypt.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 17 rows', vcr: { cassette_name: :CAE } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 17
    end
  end

  describe '#parse', vcr: { cassette_name: :CAE } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 4.969,
        AUD: 13.5171,
        BHD: 48.0106,
        CAD: 13.6542,
        CHF: 17.9617,
        DKK: 2.6006,
        EUR: 19.3471,
        GBP: 23.054,
        JOD: 25.493,
        JPY: 0.1597,
        KWD: 59.3735,
        NOK: 2.1549,
        OMR: 47.0118,
        QAR: 4.9703,
        SAR: 4.8264,
        SEK: 1.9712,
        USD: 18.1
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.8326,
        AUD: 13.0645,
        BHD: 46.7922,
        CAD: 13.2508,
        CHF: 17.4373,
        DKK: 2.5209,
        EUR: 18.7549,
        GBP: 22.1878,
        JOD: 24.8592,
        JPY: 0.1545,
        KWD: 57.8689,
        NOK: 2.0842,
        OMR: 45.8382,
        QAR: 4.8465,
        SAR: 4.7057,
        SEK: 1.9131,
        USD: 17.65
      )
    end
  end
end
