# Calcpace [![Gem Version](https://d25lcipzij17d.cloudfront.net/badge.svg?id=rb&r=r&ts=1683906897&type=6e&v=1.1.1&x2=0)](https://badge.fury.io/rb/calcpace)

Calcpace is a Ruby gem that helps with calculations related to running/cycling activities or general purposes involving distance and time. It can calculate pace, total time, and distance, accepting time in seconds or HH:MM:SS format. It also converts distances between miles and kilometers. The results are provided in a readable format, with times in HH:MM:SS or seconds and distances in X.X format. To prevent precision problems, the gem supports BigDecimal to handle the calculations, if you need, and always returns data using the same distance unit (kilometers or miles) that was used as input.

## Installation

### Add to your Gemfile

```ruby
gem 'calcpace', '~> 1.1.1'
```

Then run bundle install.

### Install the gem manually

```bash
gem install calcpace
```

### Usage

 Before calculate or convert any value, you must create a new instance of Calcpace. When you call a method, it checks the digits of the time or distance to ensure that they are in the correct format. The gem always returns data using the same distance unit (kilometers or miles) that was used as input.

### Calculate Pace

To calculate pace, provide the total time (in HH:MM:SS format) and distance (in X.X format, representing kilometers or miles). You can use the method `pace` or `pace_seconds`. If you want an extra precision in the calculations, you can pass true as parameter to the method `pace_seconds` and receive result in BigDecimal.

```ruby
calculate = Calcpace.new
calculate.pace('01:00:00', 12) # => "00:05:00"
calculate.pace('string', 12) # It must be a time (RuntimeError)
calculate.pace_seconds('01:00:00', 12) # => 300
calculate.pace_seconds('01:37:21', 12.3, true) # => 0.474878048780487804878048780487804878049e3
calculate.pace_seconds('01:37:21', 12.3) # => 474.8780487804878
```

### Calculate Total Time

To calculate total time, provide the pace (in HH:MM:SS format) and distance (in X.X format, representing kilometers or miles). You can use the method `total_time` or `total_time_seconds`. If you want an extra precision in the calculations, you can pass true as parameter to the method `total_time_seconds` and receive result in BigDecimal.

```ruby
calculate = Calcpace.new
calculate.total_time('00:05:00', 12) # => "01:00:00"
calculate.total_time('00:05:00', 'string') # It must be a XX:XX:XX time (RuntimeError)
calculate.total_time_seconds('01:37:21', 12.3) # => 71844.3
calculate.total_time_seconds('01:37:21', 12.3, true) # => 0.718443902439024390243902439024390243902e5
```

### Calculate Distance

To calculate distance, provide the running time (in HH:MM:SS format) and pace (in HH:MM:SS format). If you want an extra precision in the calculations, you can pass true as parameter to the method and receive result in BigDecimal.

```ruby
calculate = Calcpace.new
calculate.distance('01:37:21', '00:06:17') # => 15.0
calculate.distance('01:37:21', '00:06:17', true) # => 0.15493368700265251989389920424403183024e2
calculate.distance('01:37:21', 'string') # It must be a time (RuntimeError)
```

### Convert Distances

To convert distances, provide the distance and the unit of measurement (either 'km' for kilometers or 'mi' for miles). If want to change the default round of the result (2), you can pass a second parameter to the method.

```ruby
converter = Calcpace.new
converter.convert(10, 'km') # => 6.21
converter.convert(10, 'km', 1) # => 6.2
converter.convert_distance(10, 'mi') # => 16.09
converter.convert(10, 'mi', 3) # => 16.093
```

### Obtain the seconds of a time OR convert seconds to a time

To obtain the seconds of a time, provide the time in HH:MM:SS format.

```ruby
converter = Calcpace.new
converter.to_seconds('01:00:00') # => 3600
converter.to_seconds('string') # => It must be a time (RuntimeError)
converter.to_clocktime(3600) # => '01:00:00'
converter.to_clocktime('string') # => It must be a number (RuntimeError)
```

### Other Useful Methods

Calcpace also provides other useful methods to check the validity of input.

```ruby
calcpace = Calcpace.new
calcpace.check_time('01:00:00') # => nil
calcpace.check_time('01-00-00') # => It must be a XX:XX:XX time (RuntimeError)
calcpace.check_distance(10) # => nil
calcpace.check_distance('-10') # => It must be a positive number (RuntimeError)
calcpace.check_unit('km') # => nil
calcpace.check_unit('string') # => It must be a valid unit (RuntimeError)
```

## Contributing

We welcome contributions to Calcpace! To contribute, you can clone this repository and submit a pull request. Please ensure that your code adheres to our style and includes tests where appropriate.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
