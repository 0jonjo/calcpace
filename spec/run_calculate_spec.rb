# frozen_string_literal: true

require 'run_calculate'
require 'run_check'
require 'run_convert'

describe 'run_calculate' do
  context 'result' do
    it 'in correct pace' do
      expect(calculate('p', 3600, 10)).to eq('00:06:00')
    end

    it 'in correct time run ' do
      expect(calculate('t', 300, 12)).to eq('01:00:00')
    end

    it 'in correct distance' do
      expect(calculate('d', 5400, '00:05:00')).to eq(18.0)
    end

    it 'in error when unexpected calc_modal' do
      expect { calculate('x', 5400, '00:05:00') }.to raise_error('You have to choose p (pace), t (time run) or d (distance).')
    end
  end
end
