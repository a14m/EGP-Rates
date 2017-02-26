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

    it 'returns <#Enumerator::Lazy> of 13 rows',
       vcr: { cassette_name: :FaisalBank } do
      enumerator = bank.send(:raw_exchange_rates)
      expect(enumerator).to be_an Enumerator
      expect(enumerator.size).to eq 13
    end
  end

  describe '#parse', vcr: { cassette_name: :FaisalBank } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 4.2884,
        CAD: 12.0616,
        CHF: 15.7092,
        DKK: 2.2495,
        EUR: 16.7218,
        GBP: 19.7899,
        JPY: 0.140688,
        KWD: 51.6902,
        NOK: 1.8928,
        QAR: 4.3251,
        SAR: 4.2216,
        SEK: 1.757,
        USD: 15.75
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.2611,
        CAD: 11.932,
        CHF: 15.5273,
        DKK: 2.2224,
        EUR: 16.5233,
        GBP: 19.4796,
        JPY: 0.139148,
        KWD: 51.2409,
        NOK: 1.8679,
        QAR: 4.2983,
        SAR: 4.151,
        SEK: 1.7316,
        USD: 15.65
      )
    end
  end
end
