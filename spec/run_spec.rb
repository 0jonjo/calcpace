require "run"

describe Run do

  context "set distance pace and time" do
    it "#set_distance" do
      run = Run.new(0, 0, 0)
      run.set_distance(10)
      expect(run.distance).to eq(10)
    end

    it "#set_distance with negative error" do
      expect{Run.new(0, 0, 0).set_distance(-10)}.to raise_error("It can't be negative.")
    end

    it "#set_pace" do
      run = Run.new(0, 0, 0)
      run.set_pace(10)
      expect(run.pace).to eq(10)
    end

    it "#set_pace with negative error" do
      expect{Run.new(0, 0, 0).set_pace(-10)}.to raise_error("It can't be negative.")
    end

    it "#set_time" do
      run = Run.new(0, 0, 0)
      run.set_time(10)
      expect(run.time).to eq(10)
    end

    it "#set_time negative error" do
      expect{Run.new(0, 0, 0).set_time(-10)}.to raise_error("It can't be negative.")
    end
  end  
end