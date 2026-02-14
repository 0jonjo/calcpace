# Calcpace [![Gem Version](https://d25lcipzij17d.cloudfront.net/badge.svg?id=rb&r=r&ts=1683906897&type=6e&v=1.8.0&x2=0)](https://badge.fury.io/rb/calcpace)

Calcpace is a Ruby gem designed for calculations and conversions related to distance and time. It can calculate velocity, pace, total time, and distance, accepting time in various formats, including HH:MM:SS. The gem supports conversion to 42 different units, including kilometers, miles, meters, and feet. It also provides methods to validate input.

## Installation

### Add to your Gemfile

```ruby
gem 'calcpace', '~> 1.8.0'
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

Calcpace also provides methods to calculate using clocktime (HH:MM:SS or MM:SS format string). The return value will be in seconds or clocktime, depending on the method called, except for `checked_distance`. Here are some examples:

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

Use the `convert` method to convert a distance or velocity. The first parameter is the value to be converted, and the second parameter is the unit to which the value will be converted. The unit can be a string (e.g. 'km to meters') or a symbol (e.g. :km_to_meters). The gem supports 42 different units, including kilometers, miles, meters, knots, and feet.

Here are some examples:

```ruby
converter.convert(10, :km_to_meters) # => 1000
converter.convert(10, 'mi to km') # => 16.0934
converter.convert(1, :nautical_mi_to_km) # => 1.852
converter.convert(1, 'km h to m s') # => 0.277778
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

You can list all the available units [here](/lib/calcpace/converter.rb), or using `list` methods. The return will be a hash with the unit and a description of the unit.

```ruby
converter.list_all
# => {:km_to_mi=>"KM to MI", :mi_to_km=>"MI to KM", ...}

converter.list_distance
# => {:km_to_mi=>"KM to MI", :mi_to_km=>"MI to KM", ...}

converter.list_speed
# => {:m_s_to_km_h=>"M S to KM H", :km_h_to_m_s=>"KM H to M S", ...}
```

### Chain Conversions

Perform multiple conversions in sequence with the converter chain feature:

```ruby
calc = Calcpace.new

# Convert kilometers to miles to feet in one call
calc.convert_chain(1, [:km_to_mi, :mi_to_feet])
# => 3280.84 (1 km = 0.621 mi = 3280.84 feet)

# Convert with description for debugging
calc.convert_chain_with_description(100, [:meters_to_km, :km_to_mi])
# => { result: 0.0621371, description: "100 → meters_to_km → km_to_mi → 0.0621" }

# Speed conversions
calc.convert_chain(10, [:m_s_to_km_h, :km_h_to_mi_h])
# => 22.3694 (10 m/s = 36 km/h = 22.37 mi/h)
```

### Race Pace Calculator

Calcpace includes a race pace calculator for standard race distances (5K, 10K, half-marathon, and marathon):

```ruby
calc = Calcpace.new

# Calculate finish time for a race given a pace
calc.race_time(300, '5k')              # => 1500.0 (5:00/km pace for 5K = 25:00)
calc.race_time_clock('05:00', 'marathon') # => '03:30:58' (5:00/km pace for marathon)

# Calculate required pace for a target finish time
calc.race_pace('00:30:00', '5k')       # => 360.0 (need 6:00/km to finish 5K in 30:00)
calc.race_pace_clock('04:00:00', 'marathon') # => '00:05:41' (need 5:41/km for 4-hour marathon)

# List available race distances
calc.list_races
# => { '5k' => 5.0, '10k' => 10.0, 'half_marathon' => 21.0975, 'marathon' => 42.195 }
```

Supported race distances:
- `5k` - 5 kilometers
- `10k` - 10 kilometers
- `half_marathon` - 21.0975 kilometers
- `marathon` - 42.195 kilometers
- `1mile` - 1.60934 kilometers
- `5mile` - 8.04672 kilometers
- `10mile` - 16.0934 kilometers

### Pace Conversions

Convert running pace between kilometers and miles:

```ruby
calc = Calcpace.new

# Convert pace from km to miles
calc.pace_km_to_mi('05:00')           # => '00:08:02' (5:00/km = 8:02/mi)
calc.convert_pace('05:00', :km_to_mi) # => '00:08:02' (same as above)

# Convert pace from miles to km
calc.pace_mi_to_km('08:00')           # => '00:04:58' (8:00/mi ≈ 4:58/km)
calc.convert_pace('08:00', :mi_to_km) # => '00:04:58' (same as above)

# Works with numeric input (seconds) as well
calc.pace_km_to_mi(300)               # => '00:08:02' (300 seconds/km)
calc.pace_mi_to_km(480)               # => '00:04:58' (480 seconds/mi)

# String format also supported
calc.convert_pace('05:00', 'km to mi') # => '00:08:02'
```

The pace conversions are particularly useful when:
- Planning races in different countries (metric vs imperial)
- Comparing training paces with international runners
- Converting workout plans between pace formats

### Race Splits

Calculate split times for races to help pace your race strategy:

```ruby
calc = Calcpace.new

# Even pace splits for half marathon (every 5k)
calc.race_splits('half_marathon', target_time: '01:30:00', split_distance: '5k')
# => ["00:21:20", "00:42:40", "01:03:59", "01:25:19", "01:30:00"]

# Kilometer splits for 10K
calc.race_splits('10k', target_time: '00:40:00', split_distance: '1k')
# => ["00:04:00", "00:08:00", "00:12:00", ..., "00:40:00"]

# Mile splits for marathon
calc.race_splits('marathon', target_time: '03:30:00', split_distance: '1mile')
# => ["00:08:02", "00:16:04", ..., "03:30:00"]

# Negative splits strategy (second half faster)
calc.race_splits('10k', target_time: '00:40:00', split_distance: '5k', strategy: :negative)
# => ["00:20:48", "00:40:00"] # First 5k slower, second 5k faster

# Positive splits strategy (first half faster)
calc.race_splits('10k', target_time: '00:40:00', split_distance: '5k', strategy: :positive)
# => ["00:19:12", "00:40:00"] # First 5k faster, second 5k slower
```

Supported strategies:
- `:even` - Constant pace throughout (default)
- `:negative` - Second half ~4% faster (progressive race)
- `:positive` - First half ~4% faster (conservative start)

Split distances can be:
- Standard race distances: `'5k'`, `'10k'`, `'1mile'`, etc.
- Custom distances: `2.5` (in kilometers), `'3k'`, etc.

### Race Time Predictions

Predict your race times at different distances based on a recent performance using the **Riegel formula**:

```ruby
calc = Calcpace.new

# Predict marathon time from a 5K result
calc.predict_time_clock('5k', '00:20:00', 'marathon')
# => "03:11:49" (predicts 3:11:49 marathon from 20:00 5K)

# Predict 10K time from half marathon
calc.predict_time_clock('half_marathon', '01:30:00', '10k')
# => "00:40:47"

# Get predicted pace for target race
calc.predict_pace_clock('5k', '00:20:00', 'marathon')
# => "00:04:32" (4:32/km pace for predicted marathon)

# Get complete equivalent performance info
calc.equivalent_performance('10k', '00:42:00', '5k')
# => {
#      time: 1209.0,
#      time_clock: "00:20:09",
#      pace: 241.8,
#      pace_clock: "00:04:02"
#    }
```

#### How the Riegel Formula Works

The Riegel formula is a mathematical model that predicts race performance across different distances:

**Formula:** `T2 = T1 × (D2/D1)^1.06`

Where:
- **T1** = your known time at distance D1
- **T2** = predicted time at distance D2  
- **D1** = known race distance (in km)
- **D2** = target race distance (in km)
- **1.06** = fatigue/endurance factor

**The 1.06 exponent** represents how pace slows as distance increases. If endurance was perfect (1.0), doubling distance would simply double time. But in reality, you slow down slightly - the 1.06 factor accounts for this accumulated fatigue.

**Example:** From a 5K in 20:00, predict marathon time:
- T1 = 1200 seconds (20:00)
- D1 = 5 km
- D2 = 42.195 km (marathon)
- T2 = 1200 × (42.195/5)^1.06
- T2 = 1200 × 9.591 = 11,509 seconds
- T2 = **3:11:49**

The formula works best for:
- Distances from 5K to marathon
- Recent race results (within 6-8 weeks)
- Similar terrain and weather conditions
- Well-trained runners with consistent pacing

**Important notes:**
- Predictions assume equal training and effort across distances
- Results are estimates - actual performance varies by individual fitness, training focus, and race conditions
- The formula is most accurate when predicting between similar distance ranges (e.g., 10K to half marathon)

### Other Useful Methods

Calcpace also provides other useful methods:

```ruby
converter = Calcpace.new
converter.convert_to_seconds('01:00:00') # => 3600
converter.convert_to_clocktime(3600) # => '01:00:00'
converter.convert_to_clocktime(100000) # => '1 03:46:40'
converter.check_time('01:00:00') # => nil
```

### Errors

The gem now raises specific custom error classes for invalid inputs, allowing for more precise error handling. These errors inherit from `Calcpace::Error`.

- `Calcpace::NonPositiveInputError`: Raised when a numeric input is not positive.
- `Calcpace::InvalidTimeFormatError`: Raised when a time string is not in the expected `HH:MM:SS` or `MM:SS` format.

For example:

```ruby
begin
  calculate.pace(945, -1)
rescue Calcpace::NonPositiveInputError => e
  puts e.message # => "Distance must be a positive number"
end

begin
  calculate.checked_time('string', 10)
rescue Calcpace::InvalidTimeFormatError => e
  puts e.message # => "It must be a valid time in the XX:XX:XX or XX:XX format"
end
```

### Testing

To run the tests, clone the repository and run:

```bash
bundle exec rake
```

### Supported Ruby Versions

The tests are run using Ruby versions from 2.7.8 to 3.4.2, as specified in the `.github/workflows/test.yml` file.

## Contributing

We welcome contributions to Calcpace! To contribute, clone this repository and submit a pull request. Please ensure that your code adheres to our style and includes tests where appropriate.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
