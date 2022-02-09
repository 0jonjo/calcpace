require 'rspec'
require './lib/ruby-calcpace.rb'

describe Run do
  it "convert a run time to seconds" do
    expect(Run.new.convert_to_seconds("01:11:02")).to eq(4262)
  end

  it "convert seconds to a clocktime" do
    expect(Run.new.convert_to_clocktime(4262)).to eq("01:11:02")
  end

  it "convert seconds to a clocktime error negative" do
    expect{Run.new.convert_to_clocktime(-331)}.to raise_error("Clocktime can't be zero or negative.")
  end
 
  it "convert seconds to a clocktime error 0" do
    expect{Run.new.convert_to_clocktime(0)}.to raise_error("Clocktime can't be zero or negative.")
  end

  it "calculate a pace" do
    expect(Run.new.calculate_pace(3600, 10)).to eq(360)
  end  

  it "calculate a pace error negative" do
    expect{Run.new.calculate_pace(-10, 3600)}.to raise_error("Can't accept zero or negative values.")
  end

  # Have to adjust text error to sub 1 cases?
  it "calculate a pace with error sub 1" do
    expect{Run.new.calculate_pace(3599, 3600)}.to raise_error("Can't accept zero or negative values.")
  end
  
  it "calculate a pace with error time 0" do
    expect{Run.new.calculate_pace(0, 10)}.to raise_error("Can't accept zero or negative values.")
  end 

  # Have to handle divide by 0 specific error
  # it "calculate a pace error distance 0" do
  #  expect{Run.new.calculate_pace(10, 0)}.to raise_error("Pace can't be zero or negative")
  # end 

  it "calculate a time run" do
    expect(Run.new.calculate_timerun(360, 10)).to eq(3600)
  end  

  it "calculate a timerun with error negative" do
    expect{Run.new.calculate_timerun(-360, 360)}.to raise_error("Can't accept zero or negative values.")
  end

  it "calculate a timerun with error pace 0" do
    expect{Run.new.calculate_timerun(0, 360)}.to raise_error("Can't accept zero or negative values.")
  end

  it "calculate a distance" do
    expect(Run.new.calculate_distance(3600, 360)).to eq(10)
  end  

  it "calculate a distance with time error negative" do
    expect{Run.new.calculate_distance(-360, 360)}.to raise_error("Can't accept zero or negative values.")
  end

  # Have to adjust pace error to sub 1 cases?
  it "calculate a distance with pace error sub 1" do
    expect{Run.new.calculate_distance(3599, 3600)}.to raise_error("Can't accept zero or negative values.")
  end

  it "calculate a distance with error time 0" do
    expect{Run.new.calculate_distance(0, 360)}.to raise_error("Can't accept zero or negative values.")
  end

  it "set a distance negative error" do
    expect{Run.new.set_distance(-10)}.to raise_error("Distance can't be negative.")
  end

  it "set a pace negative error" do
    expect{Run.new.set_pace(-10)}.to raise_error("Pace can't be zero or negative.")
  end

  it "set a pace zero error" do
    expect{Run.new.set_pace(0)}.to raise_error("Pace can't be zero or negative.")
  end

  it "set a time negative error" do
    expect{Run.new.set_time(-10)}.to raise_error("Time can't be zero or negative.")
  end

  it "set a time zero error" do
    expect{Run.new.set_time(0)}.to raise_error("Time can't be zero or negative.")
  end

  it "set and get all run informations " do
    run = Run.new
    run.set_time(3600)
    run.set_pace(360)
    run.set_distance(10)
    expect(run.time).to eq(3600)
    expect(run.pace).to eq(360)
    expect(run.distance).to eq(10)
  end   

  it "print all run informations" do
    run = Run.new
    run.set_time(3600)
    run.set_pace(360)
    run.set_distance(10) 
    expect(run.informations_to_print).to eq("You ran 10 km in 01:00:00 at 00:06:00 pace.")
  end   
end