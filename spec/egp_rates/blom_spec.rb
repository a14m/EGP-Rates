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
        AED: 4.8324,
        BHD: 0.0,
        CAD: 13.155,
        CHF: 17.6424,
        DKK: 2.5391,
        EUR: 18.8896,
        GBP: 22.0739,
        JPY: 16.1643,
        KWD: 58.3498,
        NOK: 2.0786,
        QAR: 0.0,
        SAR: 4.7326,
        SEK: 1.9238,
        USD: 17.75
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.6284,
        BHD: 0.0,
        CAD: 12.5332,
        CHF: 16.7918,
        DKK: 2.4152,
        EUR: 17.969,
        GBP: 20.9151,
        JPY: 15.3236,
        KWD: 55.8292,
        NOK: 1.9747,
        QAR: 0.0,
        SAR: 4.5322,
        SEK: 1.8314,
        USD: 17.0
      )
    end
  end
end
