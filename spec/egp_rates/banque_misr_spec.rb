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
        AED: 4.8303,
        AUD: 13.2491,
        BHD: 47.0624,
        CAD: 13.3835,
        CHF: 17.6056,
        DKK: 2.549,
        EUR: 18.9635,
        GBP: 22.5969,
        JOD: 25.0439,
        JPY: 15.6516,
        KWD: 58.1962,
        NOK: 2.1122,
        OMR: 46.1276,
        QAR: 4.8723,
        SAR: 4.7303,
        SEK: 1.9322,
        USD: 17.75
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.7645,
        AUD: 12.9535,
        BHD: 46.4166,
        CAD: 13.1381,
        CHF: 17.2891,
        DKK: 2.4995,
        EUR: 18.5955,
        GBP: 21.9993,
        JOD: 24.6827,
        JPY: 15.3227,
        KWD: 57.377,
        NOK: 2.0682,
        OMR: 45.4133,
        QAR: 4.8053,
        SAR: 4.6654,
        SEK: 1.8968,
        USD: 17.5
      )
    end
  end
end
