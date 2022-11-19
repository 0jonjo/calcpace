require "run"

describe RunCalc do

  run = Run.new(0, 0, 0)

  context "#calculate_pace" do
    it "with all ok" do
      expect(run.calculate_pace(3600, 10)).to eq(360)
    end  

    it "with error distance negative" do
      expect{run.calculate_pace(3600, -10)}.to raise_error("It can't be negative.")
    end
  end
  
  context "#calculate_timerun" do
    it "with all ok" do
      expect(run.calculate_timerun(360, 10)).to eq(3600)
    end  

    it "with error negative" do
      expect{run.calculate_timerun(-360, 360)}.to raise_error("It can't be negative.")
    end

    it "with error pace 0" do
      expect{run.calculate_timerun(0, 360)}.to raise_error("It can't be zero.")
    end
  end

  context "#calculate_distance" do
    it "with all ok" do
      expect(run.calculate_distance(3600, 360)).to eq(10)
    end

    it "with error time negative" do
      expect{run.calculate_distance(-360, 360)}.to raise_error("It can't be negative.")
    end

    it "with error time 0" do
      expect{run.calculate_distance(0, 360)}.to raise_error("It can't be zero.")
    end
  end  
end