require "run"

describe Run do

  context "Get distance and time format" do  
    it ":check_digits_distance true X.X" do
      expect(Run.check_digits_distance('7.2')).to eq(7.2)
    end

    it ":check_digits_distance true X" do
      expect(Run.check_digits_distance('7')).to eq(7)
    end

    it ":check_digits_distance == ''" do
      expect(Run.check_digits_distance('0')).to eq(0.0)
    end

    it ":check_digits_distance not a number" do
      expect{Run.check_digits_distance('test')}.to raise_error("It must be a X.X number")
    end

    it ":check_digits_time true XX:XX:XX" do
      expect(Run.check_digits_time('01:02:03')).to eq('01:02:03')
    end

    it ":check_digits_time true X:X:X" do
      expect(Run.check_digits_time('1:2:3')).to eq('1:2:3')
    end

    it ":check_digits_time true XX:XX" do
      expect(Run.check_digits_time('01:02')).to eq('01:02')
    end

    it ":check_digits_time true XX-XX" do
      expect(Run.check_digits_time('01-02')).to eq('01:02')
    end

    it ":check_digits_time true blanket" do
      expect(Run.check_digits_time('')).to eq('')
    end

    it ":check_digits_distance not a number raise error" do
      expect{Run.check_digits_time('test')}.to raise_error("It must be a XX:XX:XX time")
    end
    
    it ":check_digits_distance AA:AA letter raise error " do
      expect{Run.check_digits_time('AA:AA')}.to raise_error("It must be a XX:XX:XX time")
    end
  end 

  context "Convert tests" do  
    it ":convert_to_seconds" do
      expect(Run.convert_to_seconds("01:11:02")).to eq(4262)
    end

    it ":convert_to_clocktime" do
      expect(Run.convert_to_clocktime(4262)).to eq("01:11:02")
    end

    it ":convert_to_clocktime error negative" do
      expect{Run.convert_to_clocktime(-331)}.to raise_error("It can't be negative.")
    end
  
    it ":convert_to_clocktime error 0" do
      expect{Run.convert_to_clocktime(0)}.to raise_error("It can't be zero.")
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
  context "#choose_calculus" do
    it "active calculate_pace" do
      expect(Run.new(3600, 0, 10, false).choose_calculus).to eq(360)
    end

    it "active calculate_timerun" do
      expect(Run.new(0, 360, 10, false).choose_calculus).to eq(3600)
    end

    it "active calculate_distance" do
      expect(Run.new(3600, 360, 0, false).choose_calculus).to eq(10)
    end

    it "raise error" do
      expect{Run.new(3600, 360, 10, false).choose_calculus}.to raise_error("It only takes two pieces of data to calculate something.")
    end
  end
end