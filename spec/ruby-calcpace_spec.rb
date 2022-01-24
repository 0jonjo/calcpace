require 'rspec'
require './lib/ruby-calcpace.rb'

describe Run do
  it "convert a run time to seconds" do
    run = Run.new
    expect(run.convert_to_seconds("01:11:02")).to eq(4262)
  end

  it "convert seconds to a clocktime" do
    run = Run.new
    expect(run.convert_to_clocktime(4262)).to eq("01:11:02")
  end
  
  it "calculate a pace" do
    run = Run.new
    expect(run.calculate_pace(3600, 10)).to eq(360)
  end  

  it "calculate a time run" do
    run = Run.new
    expect(run.calculate_timerun(360, 10)).to eq(3600)
  end  

  it "calculate a distance" do
    run = Run.new
    expect(run.calculate_distance(3600, 360)).to eq(10)
  end  

  it "recieve all run informations" do
    run = Run.new
    run.time = "01:00:00"
    run.pace = "00:06:00"
    run.distance = 10 
    expect(run.informations_to_print).to eq("You ran 10 km in 01:00:00 at 00:06:00 pace.")
  end                                       
end