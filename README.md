# Calcpace [![Gem Version](https://d25lcipzij17d.cloudfront.net/badge.svg?id=rb&r=r&ts=1683906897&type=6e&v=1.3.0&x2=0)](https://badge.fury.io/rb/calcpace)

Calcpace is a Ruby gem that helps with calculations and conversions related to distance and time. It can calculate velocity, total time, and distance, accepting time in different formats, including HH:MM:SS. The gem supports BigDecimal to handle the calculations and it can convert to 26 different units, including kilometers, miles, meters, and feet. The gem also provides methods to check the validity of the input.

## Installation

### Add to your Gemfile

```ruby
gem 'calcpace', '~> 1.3.0'
```

Then run `bundle install`.

### Install the gem manually

```bash
gem install calcpace
```

## Usage

Before calculating or converting any value, you must create a new instance of Calcpace. If you want to use BigDecimal to handle the calculations, you can pass `true` as a parameter when creating a new instance of Calcpace. Here are a few examples:

```ruby
require 'calcpace'

calculate = Calcpace.new
calculate_bigdecimal = Calcpace.new(true)
another_way_to_use_bigdecimal = Calcpace.new(bigdecimal: true)
```

### Calculate Velocity

To calculate velocity, provide the total time and then the distance as inputs. Here are some examples:

```ruby
calculate.velocity(3600, 12) # => 300
calculate.checked_velocity('01:00:00', 12) # => 300
calculate.checked_velocity('01:37:21', 12.3) # => 474.8780487804878
calculate.clock_velocity('string', 12) # It must be a time (RuntimeError)
calculate.clock_velocity('01:00:00', 12) # => "00:05:00"
calculate_bigdecimal.checked_velocity('01:37:21', 12.3) # => 0.474878048780487804878048780487804878049e3
```

### Calculate Total Time

To calculate the total time, provide the velocity and then the distance as inputs. Here are some examples:

```ruby
calculate.time(3600, 12) # => 43200
calculate.checked_time('01:37:21', 12.3) # => 71844.3
calculate.clock_time('00:05:00', 'string') # It must be a XX:XX:XX time (RuntimeError)
calculate.clock_time('00:05:00', 12) # => "01:00:00"
calculate_bigdecimal.checked_time('01:37:21', 12.3) # => 0.718443902439024390243902439024390243902e5
```

### Calculate Distance

To calculate the distance, provide the total time and then the velocity as inputs. Here are some examples:

```ruby
calculate.distance(3600, 120) # => 30
calculate.checked_distance('01:37:21', 'string') # It must be a time (RuntimeError)
calculate.checked_distance('01:37:21', '00:06:17') # => 15.0
calculate_bigdecimal.checked_distance('01:37:21', '00:06:17') # => 0.15493368700265251989389920424403183024e2
```

### Understanding the Methods

Calcpace provides three kinds of methods to calculate:

- Without checks (velocity, time, and distance):
  - Receive inputs as integers or floats.
  - Do not check the validity of the input.
  - Return an error only if the input invalidates the calculation (e.g., a string in place of a number).

- With checks (checked_velocity, checked_time, and checked_distance):
  - Check the validity of the input and return an error if the input is invalid.
  - Accept time in "HH:MM:SS" format and return the result in seconds or the inputted distance.

- With clock (clock_velocity, clock_time):
  - Same as the checked methods, but return the result in "HH:MM:SS" format.

### Convert Distances and Velocities

Use the `convert` method to convert a distance or a velocity. The first parameter is the value to be converted, and the second parameter is the unit to which the value will be converted. The unit must be a string with the abbreviation of the unit. The gem supports 26 different units, including kilometers, miles, meters, knots, and feet.

Here are some examples:

```ruby
converter.convert(10, 'KM_TO_METERS') # => 1000
converter.convert(10, 'MILES_TO_KM') # => 16.0934
converter.convert(1, 'NAUTICAL_MI_TO_KM') # => 1.852
converter.convert(1, 'KM_H_TO_M_S') # => 0.277778
converter.convert(1, 'M_S_TO_MI_H') # => 2.23694
```

List of supported distance and velocity units:

| Conversion Unit      | Description                 |
|----------------------|-----------------------------|
| KM_TO_MI             | Kilometers to Miles         |
| MI_TO_KM             | Miles to Kilometers         |
| NAUTICAL_MI_TO_KM    | Nautical Miles to Kilometers |
| KM_TO_NAUTICAL_MI    | Kilometers to Nautical Miles |
| METERS_TO_KM         | Meters to Kilometers        |
| KM_TO_METERS         | Kilometers to Meters        |
| METERS_TO_MI         | Meters to Miles             |
| MI_TO_METERS         | Miles to Meters             |
| METERS_TO_FEET       | Meters to Feet              |
| FEET_TO_METERS       | Feet to Meters              |
| METERS_TO_YARDS      | Meters to Yards             |
| YARDS_TO_METERS      | Yards to Meters             |
| METERS_TO_INCHES     | Meters to Inches            |
| INCHES_TO_METERS     | Inches to Meters            |
| M_S_TO_KM_H          | Meters per Second to Kilometers per Hour    |
| KM_H_TO_M_S          | Kilometers per Hour to Meters per Second    |
| M_S_TO_MI_H          | Meters per Second to Miles per Hour    |
| MI_H_TO_M_S          | Miles per Hour to Meters per Second    |
| M_S_TO_NAUTICAL_MI_H | Meters per Second to Nautical Miles per Hour    |
| NAUTICAL_MI_H_TO_M_S | Nautical Miles per Hour to Meters per Second    |
| M_S_TO_FEET_S        | Meters per Second to Feet per Second    |
| FEET_S_TO_M_S        | Feet per Second to Meters per Second    |
| M_S_TO_KNOTS         | Meters per Second to Knots    |
| KNOTS_TO_M_S         | Knots to Meters per Second    |
| KM_H_TO_MI_H         | Kilometers per Hour to Miles per Hour    |
| MI_H_TO_KM_H         | Miles per Hour to Kilometers per Hour    |

### Other Useful Methods

Calcpace also provides other useful methods:

```ruby
converter = Calcpace.new
converter.convert_to_seconds('01:00:00') # => 3600
converter.convert_to_clocktime(3600) # => '01:00:00'
converter.check_time('01:00:00') # => nil
converter.check_time('01-00-00') # => It must be a XX:XX:XX time (RuntimeError)
```

## Contributing

We welcome contributions to Calcpace! To contribute, you can clone this repository and submit a pull request. Please ensure that your code adheres to our style and includes tests where appropriate.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
