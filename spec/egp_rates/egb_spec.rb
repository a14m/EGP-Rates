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
        AED: 4.8326,
        AUD: 13.167,
        BHD: 47.0822,
        CAD: 13.1598,
        CHF: 17.6529,
        DKK: 2.5395,
        EUR: 18.8896,
        GBP: 22.0739,
        JOD: 25.0706,
        JPY: 0.1617,
        KWD: 58.2349,
        NOK: 2.0809,
        OMR: 46.1159,
        QAR: 4.8753,
        SAR: 4.7327,
        SEK: 1.9245,
        USD: 17.75
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.6281,
        AUD: 12.4525,
        BHD: 45.0689,
        CAD: 12.5332,
        CHF: 16.7918,
        DKK: 2.4152,
        EUR: 17.9639,
        GBP: 20.9049,
        JOD: 23.9437,
        JPY: 0.1532,
        KWD: 55.756,
        NOK: 1.9747,
        OMR: 44.1558,
        QAR: 4.6685,
        SAR: 4.5325,
        SEK: 1.8314,
        USD: 17.0
      )
    end
  end
end
