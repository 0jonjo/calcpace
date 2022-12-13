require "run"

describe Run do

  context "set distance pace and time" do
    it "#distance=" do
      run = Run.new(0, 0, 0)
      run.distance=(10)
      expect(run.distance).to eq(10)
    end

    it "#set_distance with negative error" do
      expect{Run.new(0, 0, 0).distance=(-10)}.to raise_error("It can't be negative.")
    end

    it "#pace=" do
      run = Run.new(0, 0, 0)
      run.pace=(10)
      expect(run.pace).to eq(10)
    end

    it "#set_pace with negative error" do
      expect{Run.new(0, 0, 0).pace=(-10)}.to raise_error("It can't be negative.")
    end

    it "#time=" do
      run = Run.new(0, 0, 0)
      run.time=(10)
      expect(run.time).to eq(10)
    end

    it "#time= negative error" do
      expect{Run.new(0, 0, 0).time=(-10)}.to raise_error("It can't be negative.")
    end
  end  
end