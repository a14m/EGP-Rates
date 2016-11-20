# frozen_string_literal: true
describe EGPRates::AlAhliBankOfKuwait do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 8
    expect(bank.exchange_rates[:sell].size).to eq 8
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :AlAhliBankOfKuwait
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
      stub_request(:get, /.*piraeusbank.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*piraeusbank.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 8 rows',
       vcr: { cassette_name: :AlAhliBankOfKuwait } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 8
    end
  end

  describe '#parse', vcr: { cassette_name: :AlAhliBankOfKuwait } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 4.5063,
        CHF: 16.3959,
        EUR: 17.5281,
        GBP: 20.4359,
        JPY: 0.1492,
        KWD: 54.3746,
        SAR: 4.4138,
        USD: 16.55
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.3965,
        CHF: 15.9838,
        EUR: 17.0948,
        GBP: 19.9339,
        JPY: 0.1455,
        KWD: 53.0604,
        SAR: 4.3071,
        USD: 16.15
      )
    end
  end
end
