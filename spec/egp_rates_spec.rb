# frozen_string_literal: true
describe EGPRates do
  describe '.exchange_rates' do
    # rubocop:disable RSpec/VerifiedDoubles
    context 'all Banks' do
      let(:bank) { double(EGPRates::Bank) }

      it 'calls #exchange_rates on all Bank Classes' do
        expect(described_class).to receive(:const_get).exactly(18).times
          .and_return bank
        expect(bank).to receive(:new).exactly(18).times.and_return bank
        expect(bank).to receive(:exchange_rates).exactly(18).times

        described_class.exchange_rates
      end
    end
    # rubocop:enable RSpec/VerifiedDoubles

    context '1 Bank' do
      before { allow(described_class).to receive(:constants).and_return [:CBE] }

      it 'returns [Hash] of exchange_rates', vcr: { cassette_name: :CBE } do
        exchange_rates = described_class.exchange_rates

        expect(exchange_rates).to include(:CBE)
        expect(exchange_rates[:CBE]).to include(:buy, :sell)
        expect(exchange_rates[:CBE][:buy].size).to eq 9
        expect(exchange_rates[:CBE][:sell].size).to eq 9
      end

      it 'returns [Hash] of Bank: "Failed to get exchange rates"', :no_vcr do
        stub_request(:get, /.*/).to_return(body: '', status: 500)

        exchange_rates = described_class.exchange_rates
        expect(exchange_rates).to match(CBE: 'Failed to get exchange rates')
      end
    end
  end

  describe '.exchange_rate(:SYM, cache_result)' do
    before do
      described_class.instance_variable_set(:@exchange_rates, nil)
      allow(described_class).to receive(:constants).and_return [:NBE]
    end

    context 'cache_result = true' do
      it 'calls .exchange_rates once' do
        expect(described_class).to receive(:exchange_rates).once.and_return({})

        described_class.exchange_rate(:USD)
        described_class.exchange_rate(:USD)
      end

      it 'calls .exchange_rates twice' do
        expect(described_class).to receive(:exchange_rates).twice.and_return({})

        described_class.exchange_rate(:USD)
        described_class.exchange_rate(:USD, false)
      end

      it 'returns [Hash] of Bank: "Failed to get exchange rates"', :no_vcr do
        stub_request(:get, /.*/).to_return(body: '', status: 500)

        exchange_rate = described_class.exchange_rate(:USD)
        expect(exchange_rate).to match(NBE: 'Failed to get exchange rates')
      end

      it 'returns [Hash] of Bank: { sell: rate, buy: rate }',
         vcr: { cassette_name: :NBE } do
        exchange_rate = described_class.exchange_rate(:USD)
        expect(exchange_rate).to match(NBE: { sell: 17.75, buy: 17.5 })
      end

      it 'returns [Hash] of Bank: { sell: "N/A" ... }',
         vcr: { cassette_name: :NBE } do
        exchange_rate = described_class.exchange_rate(:SYM)
        expect(exchange_rate).to match(
          NBE: { sell: 'N/A', buy: 'N/A' }
        )
      end
    end
  end
end
