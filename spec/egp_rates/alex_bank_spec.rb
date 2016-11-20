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
        AED: 4.7695,
        AUD: 12.9845,
        BHD: 0.0,
        CAD: 12.97269,
        CHF: 17.3969,
        DKK: 2.50636,
        EUR: 18.6235,
        GBP: 21.60025,
        JOD: 0.0,
        JPY: 15.77035,
        KWD: 57.6647,
        NOK: 2.05232,
        OMR: 0.0,
        QAR: 0.0,
        SAR: 4.6708,
        SEK: 1.89671,
        USD: 17.5
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.63547,
        AUD: 12.53601,
        BHD: 0.0,
        CAD: 12.6069,
        CHF: 16.89056,
        DKK: 2.42936,
        EUR: 18.0747,
        GBP: 21.12363,
        JOD: 0.0,
        JPY: 15.41791,
        KWD: 55.58396,
        NOK: 1.98636,
        OMR: 0.0,
        QAR: 0.0,
        SAR: 4.54476,
        SEK: 1.84222,
        USD: 17.1
      )
    end
  end
end
