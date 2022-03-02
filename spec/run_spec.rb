require "run"

describe Run do

  context "Convert tests" do  
    it ":convert_to_seconds" do
      expect(Run.convert_to_seconds("01:11:02")).to eq(4262)
    end

    it ":convert_to_clocktime" do
      expect(Run.convert_to_clocktime(4262)).to eq("01:11:02")
    end

    it ":convert_to_clocktime error negative" do
      expect{Run.convert_to_clocktime(-331)}.to raise_error("Clocktime can't be zero or negative.")
    end
  
    it ":convert_to_clocktime error 0" do
      expect{Run.convert_to_clocktime(0)}.to raise_error("Clocktime can't be zero or negative.")
    end
  end
  
  context "Test negative or zero" do
    it ":raise_negative" do
      expect(Run.raise_negative(5)).to eq(5)
    end 

    it ":raise_negative error" do
      expect{Run.raise_negative(-5)}.to raise_error("It can't be negative.")
    end 

    it ":raise_zero" do
      expect(Run.raise_zero(1)).to eq(1)
    end 

    it ":test_zero error" do
      expect{Run.raise_zero(0)}.to raise_error("It can't be zero.")
    end 

  end

  context "#calculate_pace" do
    it "with all ok" do
      expect(Run.new(3600, 0, 10, false).calculate_pace).to eq(360)
    end  

    it "with error distance negative" do
      expect{Run.new(3600, 0, -10, false).calculate_pace}.to raise_error("It can't be negative.")
    end

    # Have to adjust text error to sub 1 cases?
    it "with error sub 1" do
      expect{Run.new(3599, 0, 3600, false).calculate_pace}.to raise_error("It can't be zero.")
    end
    
    it "with error time 0" do
      expect{Run.new(0, 10, 10, false).calculate_pace}.to raise_error("It can't be zero.")
    end 
  
    # Have to handle divide by 0 specific error
    xit "error distance 0" do
      expect{Run.new.calculate_pace(10, 0)}.to raise_error("Pace can't be zero or negative")
    end 
  end
  
  context "#calculate_timerun" do
    it "with all ok" do
      expect(Run.new(0, 360, 10, false).calculate_timerun).to eq(3600)
    end  

    it "with error negative" do
      expect{Run.new(0, -360, 360, false).calculate_timerun}.to raise_error("It can't be negative.")
    end

    it "with error pace 0" do
      expect{Run.new(0, 0, 360, false).calculate_timerun}.to raise_error("It can't be zero.")
    end
  end

  context "#calculate_distance" do
    it "with all ok" do
      expect(Run.new(3600, 360, 0, false).calculate_distance).to eq(10)
    end

    it "with error time negative" do
      expect{Run.new(-360, 360, 0, false).calculate_distance}.to raise_error("It can't be negative.")
    end

    # Have to adjust pace error to sub 1 cases?
    it "with error pace sub 1" do
      expect{Run.new(3599, 3600, 0, false).calculate_distance}.to raise_error("It can't be zero.")
    end

    it "with error time 0" do
      expect{Run.new(0, 360, 0, false).calculate_distance}.to raise_error("It can't be zero.")
    end
  end  

  context "set distance pace and time" do
    it "#set_distance" do
      run = Run.new(0, 0, 0, false)
      run.set_distance(10)
      expect(run.distance).to eq(10)
    end

    it "#set_distance with negative error" do
      expect{Run.new(0, 0, 0, false).set_distance(-10)}.to raise_error("It can't be negative.")
    end

    it "#set_pace" do
      run = Run.new(0, 0, 0, false)
      run.set_pace(10)
      expect(run.pace).to eq(10)
    end

    it "#set_pace with negative error" do
      expect{Run.new(0, 0, 0, false).set_pace(-10)}.to raise_error("It can't be negative.")
    end

    it "#set_time" do
      run = Run.new(0, 0, 0, false)
      run.set_time(10)
      expect(run.time).to eq(10)
    end

    it "#set_time negative error" do
      expect{Run.new(0, 0, 0, false).set_time(-10)}.to raise_error("It can't be negative.")
    end

    it "#set_mph" do
      run = Run.new(0, 0, 0, false)
      run.set_mph(true) 
      expect(run.mph).to be true
    end   

    it "#set_mph error" do
      expect{Run.new(0, 0, 0, false).set_mph("teste") }.to raise_error("MPH can be only true or false.")
    end 
  end  

  context "#print_informations" do
    it "with mph false" do
      run = Run.new(3600, 360, 10, false)
      expect(run.to_s).to eq("You ran 10 km in 01:00:00 at 00:06:00 pace.")
    end
    
    it "with mph true" do
      run = Run.new(3600, 360, 10, true)
      expect(run.to_s).to eq("You ran 10 mph in 01:00:00 at 00:06:00 pace.")
    end
  end  
end