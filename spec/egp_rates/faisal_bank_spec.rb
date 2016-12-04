# frozen_string_literal: true
describe EGPRates::FaisalBank do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 13
    expect(bank.exchange_rates[:sell].size).to eq 13
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :FaisalBank
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
      stub_request(:get, /.*faisalbank.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*faisalbank.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 9 rows',
       vcr: { cassette_name: :FaisalBank } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 13
    end
  end

  describe '#parse', vcr: { cassette_name: :FaisalBank } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 4.9006,
        CAD: 13.5788,
        CHF: 17.8625,
        DKK: 2.5844,
        EUR: 19.224,
        GBP: 22.932,
        JPY: 0.1588,
        KWD: 59.0551,
        NOK: 2.1428,
        QAR: 4.9426,
        SAR: 4.825,
        SEK: 1.9604,
        USD: 18.0
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.7646,
        CAD: 13.1421,
        CHF: 17.2942,
        DKK: 2.4995,
        EUR: 18.5955,
        GBP: 22.0833,
        JPY: 0.15324,
        KWD: 57.377,
        NOK: 2.0682,
        QAR: 4.806,
        SAR: 4.6407,
        SEK: 1.8972,
        USD: 17.5
      )
    end
  end
end
