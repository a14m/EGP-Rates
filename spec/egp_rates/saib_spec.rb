# frozen_string_literal: true
describe EGPRates::SAIB do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 6
    expect(bank.exchange_rates[:sell].size).to eq 6
    expect(bank.exchange_rates[:buy].keys).to include(
      :CHF, :EUR, :GBP, :KWD, :SAR, :USD
    )
    expect(bank.exchange_rates[:sell].keys).to include(
      :CHF, :EUR, :GBP, :KWD, :SAR, :USD
    )
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :SAIB
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
      stub_request(:get, /.*saib.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*saib.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 6 rows', vcr: { cassette_name: :SAIB } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 6
    end
  end

  describe '#parse', vcr: { cassette_name: :SAIB } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        CHF: 17.98,
        EUR: 19.4,
        GBP: 22.95,
        KWD: 59.5,
        SAR: 4.83,
        USD: 18.15
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        CHF: 17.53,
        EUR: 18.91,
        GBP: 22.31,
        KWD: 58.22,
        SAR: 4.73,
        USD: 17.75
      )
    end
  end
end
