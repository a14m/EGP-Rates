# frozen_string_literal: true
describe EGPRates::Bank do
  subject(:bank) { described_class.new }

  describe '#exchange_rates' do
    it 'Raises NotImplementedError' do
      expect { bank.exchange_rates }.to raise_error NotImplementedError
    end
  end
end
