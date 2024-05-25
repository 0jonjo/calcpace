# frozen_string_literal: true

require 'run_convert'

RSpec.describe RunConvert do
  include RunConvert

  describe 'Convert tests' do
    it ':convert_to_seconds' do
      expect(convert_to_seconds('01:11:02')).to eq(4262)
    end

    it ':convert_to_clocktime' do
      expect(convert_to_clocktime(4262)).to eq('01:11:02')
    end

    it ':convert_distance km' do
      expect(convert_distance('km', 10)).to eq(6.21371)
    end

    it ':convert_distance mi' do
      expect(convert_distance('mi', 10)).to eq(16.0934)
    end
  end
end
