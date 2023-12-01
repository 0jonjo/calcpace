# frozen_string_literal: true

require 'run_calculate'
require 'run_check'
require 'run_convert'

describe 'run_calculate' do
  context 'result' do
    it 'calculates correct pace' do
      expect(calculate('p', 3600, 10)).to eq('00:06:00')
    end

    it 'calculates correct time run' do
      expect(calculate('t', 300, 12)).to eq('01:00:00')
    end

    it 'calculates correct distance' do
      expect(calculate('d', 5400, '00:05:00')).to eq(18.0)
    end
  end
end
