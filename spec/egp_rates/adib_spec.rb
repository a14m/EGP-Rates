# frozen_string_literal: true
describe EGPRates::ADIB do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 5
    expect(bank.exchange_rates[:sell].size).to eq 5
    expect(bank.exchange_rates[:buy].keys).to include(
      :AED, :EUR, :GBP, :SAR, :USD
    )
    expect(bank.exchange_rates[:sell].keys).to include(
      :AED, :EUR, :GBP, :SAR, :USD
    )
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :ADIB
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
      stub_request(:get, /.*adib.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*adib.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 5 rows', vcr: { cassette_name: :ADIB } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 5
    end
  end

  describe '#parse', vcr: { cassette_name: :ADIB } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 4.8055,
        EUR: 18.7496,
        GBP: 22.1772,
        SAR: 4.706,
        USD: 17.65
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.928,
        EUR: 19.3471,
        GBP: 23.054,
        SAR: 4.8269,
        USD: 18.1
      )
    end
  end
end
