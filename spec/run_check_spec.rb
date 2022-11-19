require "run"

describe RunCheck do
  context "ARGV" do  
    xit ":argv lenght < 3" do
      expect{ARGV = ""}.to raise_error("It must be a X.X number")
    end
  end

  context "Get distance and time format" do  
    run = Run.new(0, 0, 0)

    it ":check_digits_distance true X.X" do
      expect(run.check_digits_distance('7.2')).to eq(7.2)
    end

    it ":check_digits_distance true X" do
      expect(run.check_digits_distance('7')).to eq(7)
    end

    it ":check_digits_distance == ''" do
      expect(run.check_digits_distance('0')).to eq(0.0)
    end

    it ":check_digits_distance not a number" do
      expect{run.check_digits_distance('test')}.to raise_error("It must be a X.X number")
    end

    it ":check_digits_time true XX:XX:XX" do
      expect(run.check_digits_time('01:02:03')).to eq('01:02:03')
    end

    it ":check_digits_time true X:X:X" do
      expect(run.check_digits_time('1:2:3')).to eq('1:2:3')
    end

    it ":check_digits_time true XX:XX" do
      expect(run.check_digits_time('01:02')).to eq('01:02')
    end

    it ":check_digits_time true XX-XX" do
      expect(run.check_digits_time('01-02')).to eq('01:02')
    end

    it ":check_digits_time true blanket" do
      expect(run.check_digits_time('')).to eq('')
    end

    it ":check_digits_distance not a number raise error" do
      expect{run.check_digits_time('test')}.to raise_error("It must be a XX:XX:XX time")
    end
    
    it ":check_digits_distance AA:AA letter raise error " do
      expect{run.check_digits_time('AA:AA')}.to raise_error("It must be a XX:XX:XX time")
    end
  end   
end