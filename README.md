# Calcpace [![Gem Version](https://badge.fury.io/rb/calcpace.svg)](https://badge.fury.io/rb/calcpace)

Calcpace is a Ruby gem designed to assist with calculations related to running and cycling activities. It can calculate pace, total time, and distance, and also convert distances between miles and kilometers. Results are provided in a readable format, with times in HH:MM:SS and distances in X.X format.

## Installation

### Add to your Gemfile

```ruby
gem 'calcpace', '~> 0.2.0'
```

Then run bundle install.

### Install the gem manually

```bash
gem install calcpace
```

### Usage

### Calculate Pace

To calculate pace, provide the total time (in HH:MM:SS format) and distance (in X.X format, representing kilometers or miles).

```ruby
Calcpace.new.pace('01:00:00', 12) # => "00:05:00"
```ruby
Calcpace.new.pace('01:00:00', 12) # => "00:05:00"
```

### Calculate Total Time

To calculate total time, provide the pace (in HH:MM:SS format) and distance (in X.X format, representing kilometers or miles).
### Calculate Total Time

To calculate total time, provide the pace (in HH:MM:SS format) and distance (in X.X format, representing kilometers or miles).

```ruby
Calcpace.new.total_time('00:05:00', 12) # => "01:00:00"
```ruby
Calcpace.new.total_time('00:05:00', 12) # => "01:00:00"
```

### Calculate Distance

To calculate distance, provide the running time (in HH:MM:SS format) and pace (in HH:MM:SS format).
### Calculate Distance

To calculate distance, provide the running time (in HH:MM:SS format) and pace (in HH:MM:SS format).

```ruby
Calcpace.new.distance('01:30:00', '00:05:00') # => 18.0
```ruby
Calcpace.new.distance('01:30:00', '00:05:00') # => 18.0
```

### Convert Distances

To convert distances, provide the distance and the unit of measurement (either 'km' for kilometers or 'mi' for miles).

```ruby
Calcpace.new.convert_distance(10, 'km') # => 6.21
Calcpace.new.convert_distance(10, 'mi') # => 16.09
```

### Other Useful Methods

Calcpace also provides other useful methods to convert values and check the validity of input.

```ruby
calcpace = Calcpace.new
calcpace.convert_to_seconds('01:00:00') # => 3600
calcpace.convert_to_clock_time(3600) # => "01:00:00"
calcpace.check_digits_time('01:00:00') # => nil
calcpace.check_digits_time('01-00-00') # => It must be a XX:XX:XX time (RuntimeError)
```

### Error Handling

If the provided parameters do not meet the expected formats, Calcpace will raise an error detailing the issue. The gem always returns data using the same distance unit (kilometers or miles) that was used as input.

## Contributing

We welcome contributions to Calcpace! To contribute, you can clone this repository and submit a pull request. Please ensure that your code adheres to our style guidelines and includes tests where appropriate.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
