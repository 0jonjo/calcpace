# Calcpace [![Gem Version](https://d25lcipzij17d.cloudfront.net/badge.svg?id=rb&r=r&ts=1683906897&type=6e&v=1.0.0&x2=0)](https://badge.fury.io/rb/calcpace)

Calcpace is a Ruby gem designed to assist with calculations related to running and cycling activities. It can calculate pace, total time, and distance, and also convert distances between miles and kilometers. Results are provided in a readable format, with times in HH:MM:SS and distances in X.X format.

## Installation

### Add to your Gemfile

```ruby
gem 'calcpace', '~> 1.0.0'
```

Then run bundle install.

### Install the gem manually

```bash
gem install calcpace
```

### Usage

 Before calculate or convert any value, you must create a new instance of Calcpace. When you call a method, it checks the digits of the time or distance to ensure that they are in the correct format. The gem always returns data using the same distance unit (kilometers or miles) that was used as input.

### Calculate Pace

To calculate pace, provide the total time (in HH:MM:SS format) and distance (in X.X format, representing kilometers or miles).

```ruby
calculate = Calcpace.new
calculate.pace('01:00:00', 12) # => "00:05:00"
calculate.pace('string', 12) # It must be a time (RuntimeError)
```

### Calculate Total Time

To calculate total time, provide the pace (in HH:MM:SS format) and distance (in X.X format, representing kilometers or miles).

```ruby
calculate = Calcpace.new
calculate.total_time('00:05:00', 12) # => "01:00:00"
calculate.total_time('00:05:00', 'string') # It must be a XX:XX:XX time (RuntimeError)
```

### Calculate Distance

To calculate distance, provide the running time (in HH:MM:SS format) and pace (in HH:MM:SS format).

```ruby
Calcpace.new.distance('01:30:00', '00:05:00') # => 18.0
```

### Convert Distances

To convert distances, provide the distance and the unit of measurement (either 'km' for kilometers or 'mi' for miles).

```ruby
converter = Calcpace.new
converter.convert(10, 'km') # => 6.21
converter.convert_distance(10, 'mi') # => 16.09
```

If want to change the default round of the result (2), you can pass a second parameter to the method.

```ruby
converter = Calcpace.new
converter.convert(10, 'km', 1) # => 6.2
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
