# frozen_string_literal: true

require 'run_calculate'
require 'run_check'
require 'run_convert'

describe 'run_calculate' do
  context 'result' do
    it 'calculates correct pace' do
      expect(calculate('p', '01:00:00', 10)).to eq('00:06:00')
    end

    it 'calculates correct time run' do
      expect(calculate('t', '00:05:00', 12)).to eq('01:00:00')
    end

    it 'calculates correct distance' do
      expect(calculate('d', '01:30:00', '00:05:00')).to eq(18.0)
    end

    it 'calculates correct convert to km' do
      expect(calculate('c', 'km', '10')).to eq(6.21)
    end

    it 'calculates correct convert to mi' do
      expect(calculate('c', 'mi', '10')).to eq(16.09)
    end
  end

  context 'result' do
    it 'convert correct to km' do
      expect(convert_distance('km', 1)).to eq(0.621371)
    end

    it 'convert correct to miles' do
      expect(convert_distance('mi', 1)).to eq(1.60934)
    end
  end
end
