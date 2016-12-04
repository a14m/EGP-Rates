# frozen_string_literal: true
describe EGPRates::CBE do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 9
    expect(bank.exchange_rates[:sell].size).to eq 9
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :CBE
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
      stub_request(:get, /.*cbe.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*cbe.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 9 rows', vcr: { cassette_name: :CBE } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 9
    end
  end

  describe '#currency_symbol' do
    %W(#{'US Dollar'} Euro Sterling Swiss Japanese Saudi Kuwait UAE Chinese)\
      .each do |currency|
      it "returns currency :SYM for #{currency}" do
        symbols = %i(USD EUR GBP CHF JPY SAR KWD AED CNY)
        expect(symbols).to include(bank.send(:currency_symbol, currency))
      end
    end

    it 'raises ResponseError when Unknown Currency' do
      expect { bank.send(:currency_symbol, 'Egyptian pound') }.to raise_error\
        EGPRates::ResponseError, 'Unknown currency Egyptian pound'
    end
  end

  describe '#parse', vcr: { cassette_name: :CBE } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 4.9155,
        CHF: 17.8556,
        CNY: 2.6227,
        EUR: 19.2687,
        GBP: 22.9982,
        JPY: 15.8992,
        KWD: 59.2257,
        SAR: 4.8132,
        USD: 18.052
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.7994,
        CHF: 17.4193,
        CNY: 2.5585,
        EUR: 18.8076,
        GBP: 22.4408,
        JPY: 15.5151,
        KWD: 57.7977,
        SAR: 4.7001,
        USD: 17.6283
      )
    end
  end
end
