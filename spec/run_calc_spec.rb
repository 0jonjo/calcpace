require "run_calc"

describe "run_calc" do

  context "#calculate_pace" do
    it "with all ok" do
      expect(calculate_pace(3600, 10)).to eq(360)
    end
  end
  
  context "#calculate_timerun" do
    it "with all ok" do
      expect(calculate_timerun(360, 10)).to eq(3600)
    end
  end

  context "#calculate_distance" do
    it "with all ok" do
      expect(calculate_distance(3600, 360)).to eq(10)
    end
  end
end