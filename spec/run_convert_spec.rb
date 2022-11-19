require "run"

describe RunConvert do

  context "Convert tests" do  

    run = Run.new(0, 0, 0)

    it ":convert_to_seconds" do
      expect(run.convert_to_seconds("01:11:02")).to eq(4262)
    end

    it ":convert_to_clocktime" do
      expect(run.convert_to_clocktime(4262)).to eq("01:11:02")
    end

    it ":convert_to_clocktime error negative" do
      expect{run.convert_to_clocktime(-331)}.to raise_error("It can't be negative.")
    end
  
    it ":convert_to_clocktime error 0" do
      expect{run.convert_to_clocktime(0)}.to raise_error("It can't be zero.")
    end
  end  
end