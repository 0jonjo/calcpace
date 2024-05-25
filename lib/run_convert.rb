# frozen_string_literal: true

module RunConvert
  def convert_to_seconds(time)
    hour, minute, seconds = time.split(':').map(&:to_i)
    (hour * 3600) + (minute * 60) + seconds
  end

  def convert_to_clocktime(seconds)
    Time.at(seconds).utc.strftime('%H:%M:%S')
  end

  def convert_distance(unit, distance)
    case unit
    when 'km'
      distance * 0.621371
    when 'mi'
      distance * 1.60934
    end
  end
end
