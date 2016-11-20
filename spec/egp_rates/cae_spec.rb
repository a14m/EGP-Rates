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
        AED: 4.8869,
        AUD: 13.3153,
        BHD: 47.6102,
        CAD: 13.3032,
        CHF: 17.8412,
        DKK: 2.5677,
        EUR: 19.1024,
        GBP: 22.3226,
        JOD: 25.2817,
        JPY: 0.1635,
        KWD: 58.8718,
        NOK: 2.102,
        OMR: 46.6222,
        QAR: 4.9294,
        SAR: 4.7864,
        SEK: 1.9455,
        USD: 17.95
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.6962,
        AUD: 12.646,
        BHD: 45.7317,
        CAD: 12.7175,
        CHF: 17.0387,
        DKK: 2.4507,
        EUR: 18.2333,
        GBP: 21.2227,
        JOD: 24.2958,
        JPY: 0.1555,
        KWD: 56.5759,
        NOK: 2.0022,
        OMR: 44.8017,
        QAR: 4.7367,
        SAR: 4.5989,
        SEK: 1.8584,
        USD: 17.25
      )
    end
  end
end
