# Calcpace [![Gem Version](https://d25lcipzij17d.cloudfront.net/badge.svg?id=rb&r=r&ts=1683906897&type=6e&v=1.5.2&x2=0)](https://badge.fury.io/rb/calcpace)

Calcpace is a Ruby gem designed for calculations and conversions related to distance and time. It can calculate velocity, pace, total time, and distance, accepting time in various formats, including HH:MM:SS. The gem supports conversion to 42 different units, including kilometers, miles, meters, and feet. It also provides methods to validate input.

## Installation

### Add to your Gemfile

```ruby
gem 'calcpace', '~> 1.5.2'
```

Then run:

```bash
bundle install
```

### Install the gem manually

```bash
gem install calcpace
```

## Usage

Before performing any calculations or conversions, create a new instance of Calcpace:

```ruby
require 'calcpace'

calculate = Calcpace.new
```

### Calculate using Integers or Floats

Calcpace provides methods to calculate velocity, pace, total time, and distance. The methods are unit-agnostic, and the return value is a float. Here are some examples:

```ruby
calculate.velocity(3625, 12275) # => 3.386206896551724
calculate.pace(3665, 12) # => 305.4166666666667
calculate.time(210, 12) # => 2520.0
calculate.distance(9660, 120) # => 80.5
```

Tip: Use the `round` method to round a float. For example:

```ruby
calculate.velocity(3625, 12275).round(3) # => 3.386
```

Remember:

- Velocity is the distance divided by the time (e.g., m/s or km/h).
- Pace is the time divided by the distance (e.g., minutes/km or minutes/miles).
- Total time is the distance divided by the velocity.
- Distance is the velocity multiplied by the time.

### Calculate using Clocktime

Calcpace also provides methods to calculate using clocktime (HH:MM:SS format string). The return value will be in seconds or clocktime, depending on the method called, except for `checked_distance`. Here are some examples:

```ruby
# The return will be in the unit you input/seconds or seconds/unit you input
calculate.checked_velocity('01:00:00', 12275) # => 3.4097222222222223
calculate.checked_pace('01:21:32', 10) # => 489.2
calculate.checked_time('00:05:31', 12.6) # => 4170.599999999999

calculate.checked_distance('01:21:32', '00:06:27') # => 12.640826873385013

# The return will be in clocktime
calculate.clock_pace('01:21:32', 10) # => "00:08:09"
calculate.clock_velocity('01:00:00', 10317) # => "00:00:02"
calculate.clock_time('00:05:31', 12.6) # => "01:09:30"
```

Note: Using the `clock` methods may be less precise than using other methods due to conversions.

You can also use BigDecimal for more precise calculations. For example:

```ruby
require 'bigdecimal'
calculate.checked_velocity('10:00:00', 10317).to_d # => #<BigDecimal:7f9f1b8b1d08,'0.2865833333 333333E1',27(36)>
```

To learn more about BigDecimal, check the [documentation](https://ruby-doc.org/stdlib-2.7.1/libdoc/bigdecimal/rdoc/BigDecimal.html).

### Convert Distances and Velocities

Use the `convert` method to convert a distance or velocity. The first parameter is the value to be converted, and the second parameter is the unit to which the value will be converted. The unit must be a string with the abbreviation of the unit. The gem supports 26 different units, including kilometers, miles, meters, knots, and feet.

Here are some examples:

```ruby
converter.convert(10, :km_to_meters) # => 1000
converter.convert(10, :mi_to_km) # => 16.0934
converter.convert(1, :nautical_mi_to_km) # => 1.852
converter.convert(1, :km_h_to_m_s) # => 0.277778
converter.convert(1, :m_s_to_mi_h) # => 2.23694
```

| Conversion Unit      | Description                 |
|----------------------|-----------------------------|
| :km_to_mi            | Kilometers to Miles         |
| :mi_to_km            | Miles to Kilometers         |
| :nautical_mi_to_km   | Nautical Miles to Kilometers |
| :km_to_nautical_mi   | Kilometers to Nautical Miles |
| :meters_to_km        | Meters to Kilometers        |
| :km_to_meters        | Kilometers to Meters        |
| :meters_to_mi        | Meters to Miles             |
| :mi_to_meters        | Miles to Meters             |
| :m_s_to_km_h         | Meters per Second to Kilometers per Hour    |
| :km_h_to_m_s         | Kilometers per Hour to Meters per Second    |
| :m_s_to_mi_h         | Meters per Second to Miles per Hour    |
| :mi_h_to_m_s         | Miles per Hour to Meters per Second    |
| :m_s_to_feet_s       | Meters per Second to Feet per Second    |
| :feet_s_to_m_s       | Feet per Second to Meters per Second    |
| :km_h_to_mi_h        | Kilometers per Hour to Miles per Hour    |
| :mi_h_to_km_h        | Miles per Hour to Kilometers per Hour    |

You can list all the available units [here](/lib/calcpace/converter.rb), or using `list` methods:

```ruby
converter.list_all
converter.list_distance
converter.list_speed
```

### Other Useful Methods

Calcpace also provides other useful methods:

```ruby
converter = Calcpace.new
converter.convert_to_seconds('01:00:00') # => 3600
converter.convert_to_clocktime(3600) # => '01:00:00'
converter.converto_to_clocktime(100000) # => '1 03:46:40'
converter.check_time('01:00:00') # => nil
```

### Errors

If you input an invalid value, the gem will raise a `ArgumentError` with a message explaining the error. For example:

```ruby
calculate.pace(945, -1) # => It must be a X.X positive number (ArgumentError)
calculate.checked_time('string', 10) # => It must be a XX:XX:XX time (ArgumentError)
converter.check_time('01-00-00') # => It must be a XX:XX:XX time (ArgumentError)
```

## Contributing

We welcome contributions to Calcpace! To contribute, clone this repository and submit a pull request. Please ensure that your code adheres to our style and includes tests where appropriate.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
