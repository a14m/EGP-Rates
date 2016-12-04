# frozen_string_literal: true
describe EGPRates::AlexBank do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 17
    expect(bank.exchange_rates[:sell].size).to eq 17
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :AlexBank
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
      stub_request(:get, /.*alexbank.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*alexbank.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 17 rows',
       vcr: { cassette_name: :AlexBank } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 17
    end
  end

  describe '#currency_symbol' do
    %W(#{'UAE Dirham'} Australian Bahraini Canadian Swidish Danish Euro
       Japanese Swiss British Jordanian Kuwaiti Norwegian Omani Qatari Saudi
       #{'US Dollar'})
      .each do |currency|
      it "returns currency :SYM for #{currency}" do
        symbols = %i(USD AUD BHD GBP CAD DKK AED EUR CHF SEK JPY JOD NOK OMR QAR
                     SAR KWD)
        expect(symbols).to include(bank.send(:currency_symbol, currency))
      end
    end

    it 'raises ResponseError when Unknown Currency' do
      expect { bank.send(:currency_symbol, 'EGYPTIAN POUND') }.to raise_error\
        EGPRates::ResponseError, 'Unknown currency EGYPTIAN POUND'
    end
  end

  describe '#parse', vcr: { cassette_name: :AlexBank } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 4.91437,
        AUD: 13.47974,
        BHD: 0.0,
        CAD: 13.61648,
        CHF: 17.91208,
        DKK: 2.59343,
        EUR: 19.29365,
        GBP: 22.97765,
        JOD: 0.0,
        JPY: 15.92413,
        KWD: 59.21916,
        NOK: 2.14896,
        OMR: 0.0,
        QAR: 0.0,
        SAR: 4.81269,
        SEK: 1.9658,
        USD: 18.05
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.77717,
        AUD: 13.04232,
        BHD: 0.0,
        CAD: 13.22823,
        CHF: 17.40763,
        DKK: 2.5166,
        EUR: 18.72301,
        GBP: 22.44788,
        JOD: 0.0,
        JPY: 15.42772,
        KWD: 57.29892,
        NOK: 2.08237,
        OMR: 0.0,
        QAR: 0.0,
        SAR: 4.68342,
        SEK: 1.90982,
        USD: 17.62
      )
    end
  end
end
