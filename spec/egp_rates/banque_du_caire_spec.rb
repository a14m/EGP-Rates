# frozen_string_literal: true
describe EGPRates::BanqueDuCaire do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 17
    expect(bank.exchange_rates[:sell].size).to eq 17
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :BanqueDuCaire
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
      stub_request(:get, /.*banqueducaire.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*banqueducaire.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 17 rows',
       vcr: { cassette_name: :BanqueDuCaire } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 17
    end
  end

  describe '#currency_symbol' do
    %W(#{'US DOLLAR'} AUSTRALIAN BAHRAIN BRITISH CANADIAN DANISH EMIRATES EURO
       JAPANESE JORDANIAN NORWEGIAN OMANI QATAR SAUDI KUWAITI SWISS SWEDISH)
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

  describe '#parse', vcr: { cassette_name: :BanqueDuCaire } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 4.4248,
        AUD: 12.3971,
        BHD: 43.139,
        CAD: 12.0818,
        CHF: 16.5378,
        DKK: 2.3854,
        EUR: 17.7499,
        GBP: 20.5936,
        JOD: 22.952,
        JPY: 15.3302,
        KWD: 53.662,
        NOK: 1.9477,
        OMR: 42.219,
        QAR: 4.464,
        SAR: 4.3351,
        SEK: 1.8017,
        USD: 16.25
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.174,
        AUD: 11.5417,
        BHD: 39.359,
        CAD: 11.3309,
        CHF: 15.5129,
        DKK: 2.2338,
        EUR: 16.6194,
        GBP: 19.2197,
        JOD: 21.394,
        JPY: 14.3552,
        KWD: 48.862,
        NOK: 1.819,
        OMR: 38.375,
        QAR: 4.194,
        SAR: 4.0501,
        SEK: 1.6843,
        USD: 15.35
      )
    end
  end
end
