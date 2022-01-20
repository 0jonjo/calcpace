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
    runtime = run.convert_to_seconds('01:00:00')
    expect(run.calculate_pace(runtime, 10)).to eq(360)
  end  

  it "calculate a time run" do
    run = Run.new
    pace = run.convert_to_seconds('00:06:00')
    expect(run.calculate_timerun(pace, 10)).to eq(3600)
  end  

end