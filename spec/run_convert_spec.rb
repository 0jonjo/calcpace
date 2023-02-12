require "run_convert"

describe "run_convert" do

  context "Convert tests" do

    it ":convert_to_seconds" do
      expect(convert_to_seconds("01:11:02")).to eq(4262)
    end

    it ":convert_to_clocktime" do
      expect(convert_to_clocktime(4262)).to eq("01:11:02")
    end
  end
end