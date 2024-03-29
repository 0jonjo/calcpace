# CALCPACE

A TDD Ruby study project to calculate the running pace, the predicted running time or distance. It's based on my original [Python Calcpace](https://github.com/0jonjo/calcpace-py).

## Install

### Clone the repository

```shell
git clone git@github.com:0jonjo/ruby-calcpace.git
cd ruby-calcpace
```

### Install dependencies

Using [Bundler](https://github.com/bundler/bundler)

```shell
bundle install
```

## Use the calculator

Use main.rb informs the calculation option and the running (jogging) data.

Choose p to calculate pace and enter running time (HH:MM:SS) and distance (X.X) in kilometers or miles.

```shell
ruby lib/main.rb p 01:00:00 10
00:06:00
```

Choose t to calculate running time and enter pace (HH:MM:SS) and distance (X.X) in kilometers or miles.

```shell
ruby lib/main.rb t 00:05:00 12
01:00:00
```

Choose d to calculate distance in kilometers or miles and enter running time (HH:MM:SS) and pace (HH:MM:SS).

```shell
ruby lib/main.rb d 01:30:00 00:05:00
18.0
```

Choose c to convert distance.

Enter km and the distance in kilometers to convert to miles.

```shell
ruby lib/main.rb c km 10
6.21
```

Enter mi and the distance in miles to convert to kilometers.

```shell
ruby lib/main.rb c mi 10
16.09
```

If some of the parameters are not in the standard that the program uses, it informs what the problem is in an error.

It's important to input data using the same standard (kilometers or miles) to obtain the correct result.
