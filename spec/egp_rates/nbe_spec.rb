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

  describe '#exchange_rates' do
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
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 4.8327,
        AUD: 13.2557,
        BHD: 47.086,
        CAD: 13.3902,
        CHF: 17.6144,
        DKK: 2.5503,
        EUR: 18.973,
        GBP: 22.6082,
        JOD: 25.0565,
        JPY: 15.6595,
        KWD: 58.2254,
        NOK: 2.1132,
        OMR: 46.1506,
        QTR: 4.8748,
        SAR: 4.7327,
        SEK: 1.9331,
        USD: 17.75
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.7645,
        AUD: 12.9535,
        BHD: 46.4166,
        CAD: 13.1381,
        CHF: 17.2891,
        DKK: 2.4995,
        EUR: 18.5955,
        GBP: 21.9993,
        JOD: 24.6827,
        JPY: 15.3227,
        KWD: 57.377,
        NOK: 2.0682,
        OMR: 45.4133,
        QTR: 4.8053,
        SAR: 4.6654,
        SEK: 1.8968,
        USD: 17.5
      )
    end
  end
end
