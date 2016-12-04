# frozen_string_literal: true
describe EGPRates::CIB do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 6
    expect(bank.exchange_rates[:sell].size).to eq 6
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :CIB
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
      stub_request(:post, /.*cib.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if JSON respnonse changed', :no_vcr do
      stub_request(:post, /.*cib.*/).to_return(
        body: { d: { USD: 1 } }.to_json,
        status: 200
      )
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, /Unknown JSON/
    end

    it 'raises ResponseError if empty JSON respnonse', :no_vcr do
      stub_request(:post, /.*cib.*/).to_return(body: '"{}"', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, /Unknown JSON/
    end

    it 'raises ResponseError if malformed JSON respnonse', :no_vcr do
      stub_request(:post, /.*cib.*/).to_return(body: '{ data', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, /Unknown JSON/
    end

    it 'raises ResponseError if empty respnonse', :no_vcr do
      stub_request(:post, /.*cib.*/).to_return(body: '""', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, /Unknown JSON/
    end

    it 'returns Hash of 6 currencies rates', vcr: { cassette_name: :CIB } do
      response = bank.send(:raw_exchange_rates)
      expect(response.size).to eq 1
      expect(response['d'].size).to eq 6
    end
  end

  describe '#parse', vcr: { cassette_name: :CIB } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        CHF: 17.6266,
        EUR: 18.973,
        GBP: 22.6082,
        KWD: 58.2254,
        SAR: 4.7331,
        USD: 17.75
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        CHF: 17.2891,
        EUR: 18.5903,
        GBP: 21.9888,
        KWD: 57.3667,
        SAR: 4.659,
        USD: 17.5
      )
    end
  end
end
