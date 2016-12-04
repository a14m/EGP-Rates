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
        AED: 4.8332,
        AUD: 13.2557,
        BHD: 47.088,
        CAD: 13.3952,
        CHF: 17.6266,
        DKK: 2.5509,
        EUR: 18.973,
        GBP: 22.6082,
        JOD: 25.071,
        JPY: 15.6678,
        KWD: 58.244,
        NOK: 2.1157,
        OMR: 46.11,
        QAR: 4.876,
        SAR: 4.7352,
        SEK: 1.934,
        USD: 17.75
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.7587,
        AUD: 12.9413,
        BHD: 44.872,
        CAD: 13.1381,
        CHF: 17.2891,
        DKK: 2.4995,
        EUR: 18.5903,
        GBP: 21.9888,
        JOD: 24.39,
        JPY: 15.3227,
        KWD: 55.476,
        NOK: 2.0682,
        OMR: 43.75,
        QAR: 4.781,
        SAR: 4.6174,
        SEK: 1.8968,
        USD: 17.5
      )
    end
  end
end
