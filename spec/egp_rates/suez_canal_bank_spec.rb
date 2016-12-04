# frozen_string_literal: true
describe EGPRates::SuezCanalBank do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 13
    expect(bank.exchange_rates[:sell].size).to eq 13
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :SuezCanalBank
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
      stub_request(:get, /.*scbank.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*scbank.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 13 rows',
       vcr: { cassette_name: :SuezCanalBank } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 13
    end
  end

  describe '#currency_symbol' do
    %W(#{'UAE Dirham'} Australian Canadian Swedish Danish EUR YEN Swiss
       Sterling Kuwaiti Norwegian Saudi #{'US Dollar'})
      .each do |currency|
      it "returns currency :SYM for #{currency}" do
        symbols = %i(USD AUD GBP CAD DKK AED EUR CHF SEK JPY NOK SAR KWD)
        expect(symbols).to include(bank.send(:currency_symbol, currency))
      end
    end

    it 'raises ResponseError when Unknown Currency' do
      expect { bank.send(:currency_symbol, 'Egyptian Pound') }.to raise_error\
        EGPRates::ResponseError, 'Unknown currency Egyptian Pound'
    end
  end

  describe '#parse', vcr: { cassette_name: :SuezCanalBank } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 0.0,
        AUD: 0.0,
        CAD: 0.0,
        CHF: 17.8749,
        DKK: 0.0,
        EUR: 19.2402,
        GBP: 22.9266,
        JPY: 0.0,
        KWD: 0.0,
        NOK: 0.0,
        SAR: 4.8003,
        SEK: 0.0,
        USD: 18.0
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 0.0,
        AUD: 0.0,
        CAD: 0.0,
        CHF: 17.3879,
        DKK: 0.0,
        EUR: 18.6965,
        GBP: 22.1144,
        JPY: 0.0,
        KWD: 0.0,
        NOK: 0.0,
        SAR: 4.6714,
        SEK: 0.0,
        USD: 17.6
      )
    end
  end
end
