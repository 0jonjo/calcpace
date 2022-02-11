require 'rspec'
require './src/run.rb'

describe Run do
  it "convert a run time to seconds" do
    expect(Run.convert_to_seconds("01:11:02")).to eq(4262)
  end

  it "convert seconds to a clocktime" do
    expect(Run.convert_to_clocktime(4262)).to eq("01:11:02")
  end

  it "convert seconds to a clocktime error negative" do
    expect{Run.convert_to_clocktime(-331)}.to raise_error("Clocktime can't be zero or negative.")
  end
 
  it "convert seconds to a clocktime error 0" do
    expect{Run.convert_to_clocktime(0)}.to raise_error("Clocktime can't be zero or negative.")
  end

  it "calculate a pace" do
    expect(Run.new(3600, 0, 10, false).calculate_pace).to eq(360)
  end  

  it "calculate a pace error distance negative" do
    expect{Run.new(3600, 0, -10, false).calculate_pace}.to raise_error("Can't accept zero or negative values.")
  end

  # Have to adjust text error to sub 1 cases?
  it "calculate a pace with error sub 1" do
    expect{Run.new(3599, 0, 3600, false).calculate_pace}.to raise_error("Can't accept zero or negative values.")
  end
  
  it "calculate a pace with error time 0" do
    expect{Run.new(0, 10, 10, false).calculate_pace}.to raise_error("Can't accept zero or negative values.")
  end 

  # Have to handle divide by 0 specific error
  # it "calculate a pace error distance 0" do
  #  expect{Run.new.calculate_pace(10, 0)}.to raise_error("Pace can't be zero or negative")
  # end 

  it "calculate a time run" do
    expect(Run.new(0, 360, 10, false).calculate_timerun).to eq(3600)
  end  

  it "calculate a timerun with error negative" do
    expect{Run.new(0, -360, 360, false).calculate_timerun}.to raise_error("Can't accept zero or negative values.")
  end

  it "calculate a timerun with error pace 0" do
    expect{Run.new(0, 0, 360, false).calculate_timerun}.to raise_error("Can't accept zero or negative values.")
  end

  it "calculate a distance" do
    expect(Run.new(3600, 360, 0, false).calculate_distance).to eq(10)
  end  

  it "calculate a distance with time error negative" do
    expect{Run.new(-360, 360, 0, false).calculate_distance}.to raise_error("Can't accept zero or negative values.")
  end

  # Have to adjust pace error to sub 1 cases?
  it "calculate a distance with pace error sub 1" do
    expect{Run.new(3599, 3600, 0, false).calculate_distance}.to raise_error("Can't accept zero or negative values.")
  end

  it "calculate a distance with error time 0" do
    expect{Run.new(0, 360, 0, false).calculate_distance}.to raise_error("Can't accept zero or negative values.")
  end

  it "set a distance negative error" do
    expect{Run.new(0, 0, 0, false).set_distance(-10)}.to raise_error("Distance can't be negative.")
  end

  it "set a pace negative error" do
    expect{Run.new(0, 0, 0, false).set_pace(-10)}.to raise_error("Pace can't be negative.")
  end

  it "set a time negative error" do
    expect{Run.new(0, 0, 0, false).set_time(-10)}.to raise_error("Time can't be negative.")
  end

  it "set and get all time pace distance" do
    run = Run.new(0, 0, 0, false)
    run.set_time(3600)
    run.set_pace(360)
    run.set_distance(10)
    expect(run.time).to eq(3600)
    expect(run.pace).to eq(360)
    expect(run.distance).to eq(10)
  end   

  it "set to run to MPH" do
    run = Run.new(0, 0, 0, false)
    run.set_mph(true) 
    expect(run.mph).to eq(true)
    run.set_mph(false) 
    expect(run.mph).to eq(false)
  end   

  it "print all run informations" do
    run = Run.new(3600, 360, 10, false)
    expect(run.to_s).to eq("You ran 10 km in 01:00:00 at 00:06:00 pace.")
  end
  
  it "print all run informations with mph true" do
    run = Run.new(3600, 360, 10, true)
    expect(run.to_s).to eq("You ran 10 mph in 01:00:00 at 00:06:00 pace.")
  end
  
end