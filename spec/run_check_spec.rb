# frozen_string_literal: true

require 'run_check'

describe 'run_check' do
  context 'ARGV' do
    it ':argv length < 3' do
      expect { check_argv_length([0, 0]) }.to raise_error('It must be exactly three arguments')
    end

    it 'check_argv_modal pass correct input' do
      expect { check_argv_modal('p') }.not_to raise_error
    end

    it 'check_argv_modal raise error when incorrect input' do
      expect { check_argv_modal('z') }.to raise_error('You have to choose p (pace), t (time run), d (distance) or c (convert).')
    end
  end

  context 'Check negative digits' do
    it ':raise_negative when receive negative number' do
      expect { raise_negative(-1) }.to raise_error("It can't be negative.")
    end

    it 'not raise_negative when receive positive number' do
      expect { raise_negative(1) }.not_to raise_error
    end

    it 'not raise_negative when receive positive number' do
      expect { raise_negative('00:05:00'.to_i) }.not_to raise_error
    end
  end

  context 'Get distance and time format' do
    it ':check_digits_distance true X.X' do
      expect(check_digits_distance('7.2')).to eq(7.2)
    end

    it ':check_digits_distance true X' do
      expect(check_digits_distance('7')).to eq(7)
    end

    it ":check_digits_distance == ''" do
      expect(check_digits_distance('0')).to eq(0.0)
    end

    it ':check_digits_distance not a number' do
      expect { check_digits_distance('test') }.to raise_error('It must be a X.X number')
    end

    it ':check_digits_time true XX:XX:XX' do
      expect(check_digits_time('01:02:03')).to eq('01:02:03')
    end

    it ':check_digits_time true X:X:X' do
      expect(check_digits_time('1:2:3')).to eq('1:2:3')
    end

    it ':check_digits_time true XX:XX' do
      expect(check_digits_time('01:02')).to eq('01:02')
    end

    it ':check_digits_time true XX-XX' do
      expect(check_digits_time('01-02')).to eq('01:02')
    end

    it ':check_digits_time true blanket' do
      expect { check_digits_time('') }.to raise_error('It must be a XX:XX:XX time')
    end

    it 'check_digits_time true XX:XX' do
      expect { check_digits_time('AA:AA') }.to raise_error('It must be a XX:XX:XX time')
      expect { check_digits_time('test') }.to raise_error('It must be a XX:XX:XX time')
    end

    it ':check_digits_time AA:AA letter raise error ' do
      expect { check_digits_time('AA:AA') }.to raise_error('It must be a XX:XX:XX time')
    end
  end
end
