# frozen_string_literal: true
describe EGPRates::BanqueMisr do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 17
    expect(bank.exchange_rates[:sell].size).to eq 17
    expect(bank.exchange_rates[:buy].keys).to include(
      :USD, :AUD, :BHD, :GBP, :CAD, :DKK, :AED, :EUR, :CHF, :SEK,
      :JPY, :JOD, :NOK, :OMR, :QAR, :SAR, :KWD
    )
    expect(bank.exchange_rates[:sell].keys).to include(
      :USD, :AUD, :BHD, :GBP, :CAD, :DKK, :AED, :EUR, :CHF, :SEK,
      :JPY, :JOD, :NOK, :OMR, :QAR, :SAR, :KWD
    )
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :BanqueMisr
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
      stub_request(:get, /.*banquemisr.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*banquemisr.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 17 rows',
       vcr: { cassette_name: :BanqueMisr } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 17
    end
  end

  describe '#currency_symbol' do
    %W(#{'UAE DIRHAM'} AUSTRALIA BAHRAIN CANADA SWEDISH DENMARK EURO JAPAN SWISS
       #{'GB POUND'} JORDANIAN KUWAIT NORWAY OMAN QATARI SAUDI #{'US DOLLAR'})
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

  describe '#parse', vcr: { cassette_name: :BanqueMisr } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 4.3294,
        AUD: 12.1317,
        BHD: 42.1928,
        CAD: 11.8178,
        CHF: 1.7622,
        DKK: 2.334,
        EUR: 17.3698,
        GBP: 20.1527,
        JOD: 22.4478,
        JPY: 14.9963,
        KWD: 52.534,
        NOK: 1.9046,
        OMR: 41.3147,
        QAR: 4.3677,
        SAR: 4.24,
        SEK: 16.1754,
        USD: 15.91
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.179,
        AUD: 11.5524,
        BHD: 40.6957,
        CAD: 11.3309,
        CHF: 1.6843,
        DKK: 2.2338,
        EUR: 16.6256,
        GBP: 19.2289,
        JOD: 21.6594,
        JPY: 14.3552,
        KWD: 50.5599,
        NOK: 1.819,
        OMR: 39.8339,
        QAR: 4.2154,
        SAR: 4.0927,
        SEK: 15.5129,
        USD: 15.35
      )
    end
  end
end
