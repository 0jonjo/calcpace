# frozen_string_literal: true

module EnvironmentalAdjuster
  # Turns air temperature plus humidity into the effective temperature the heat
  # curve is read at.
  #
  # The heat curve is keyed on air temperature, but heat stress depends on
  # humidity too: sweat evaporates less in humid air. Wet-bulb globe temperature
  # (WBGT) captures both. The Australian Bureau of Meteorology's simplified WBGT,
  # for outdoor conditions with moderate sun and light wind, is
  #
  #   WBGT = 0.567·Ta + 0.393·e + 3.94
  #   e    = RH/100 · 6.105·exp(17.27·Ta / (237.7 + Ta))   (hPa)
  #
  # The effective temperature is the air temperature that, at
  # REFERENCE_HUMIDITY, has the same WBGT as the real (temperature, humidity)
  # pair: WBGT(T_eff, REFERENCE_HUMIDITY) = WBGT(T, RH). Solving that equation
  # (rather than adding ΔWBGT / 0.567) keeps the reference air's own vapour
  # pressure rising with temperature, as it does along the temperature-only
  # curve; the shortcut would roughly double the humidity effect at 30 °C.
  module Humidity
    # Relative humidity (%) the temperature-only heat curve stands for. The heat
    # points were calibrated against Ely et al.'s WBGT figures while the input
    # is air temperature, and the simplified WBGT equals the air temperature at
    # 51–56% RH between 20 °C and 35 °C — so a temperature-only reading is a
    # reading at about 50% humidity. humidity: 50 gives the same numbers as no
    # humidity at all.
    REFERENCE_HUMIDITY = 50.0

    # Simplified WBGT coefficients (Australian Bureau of Meteorology)
    WBGT_TEMPERATURE_COEFFICIENT = 0.567
    WBGT_VAPOUR_PRESSURE_COEFFICIENT = 0.393

    # Bisection: the bracket is ±40 °C around the air temperature (0–100% RH
    # moves the effective temperature by far less) and 60 halvings take it
    # below 1e-16 °C
    BRACKET_CELSIUS = 40.0
    BISECTION_STEPS = 60

    # Lowest accepted dew point (°C). The Magnus formula has a pole at
    # −237.7 °C, and no weather on Earth has a dew point anywhere near −100 °C.
    MIN_DEW_POINT_CELSIUS = -100.0

    module_function

    # @param temp [Numeric, nil] air temperature in any unit (nil = none given)
    # @param humidity [Object] relative humidity input
    # @param dew_point [Object] dew point input
    # @raise [ArgumentError] if the combination or a value is invalid
    def check_inputs!(temp, humidity, dew_point)
      return if humidity.nil? && dew_point.nil?
      raise ArgumentError, 'Pass either humidity or dew_point, not both' if humidity && dew_point
      raise ArgumentError, 'humidity and dew_point need a finite temperature' unless finite_number?(temp)

      check_values!(humidity, dew_point)
    end

    def check_values!(humidity, dew_point)
      unless valid_dew_point?(dew_point)
        raise ArgumentError, "dew_point must be a finite number (got #{dew_point.inspect})"
      end
      return if valid_humidity?(humidity)

      raise ArgumentError, "humidity must be a relative humidity between 0 and 100 (got #{humidity.inspect})"
    end

    # @param temp_c [Float] air temperature in °C
    # @param humidity [Numeric, nil] relative humidity in %
    # @param dew_point_c [Numeric, nil] dew point in °C (used when humidity is nil)
    # @return [Float] effective temperature in °C, unrounded (round only for
    #   display, so that humidity: REFERENCE_HUMIDITY reads the curve at
    #   exactly the air temperature)
    # @raise [ArgumentError] if the dew point is above the air temperature or
    #   below MIN_DEW_POINT_CELSIUS
    def effective_temperature(temp_c, humidity: nil, dew_point_c: nil)
      # The exact solution; bisection would land within an ulp of it, which a
      # later rounding step can still tip over a boundary
      return temp_c if humidity == REFERENCE_HUMIDITY

      vapour = humidity ? humidity / 100.0 * saturation_vapour_pressure(temp_c) : dew_point_vapour(dew_point_c, temp_c)
      temperature_at_reference_humidity(temp_c, vapour)
    end

    # Saturation vapour pressure in hPa (the Magnus form the Bureau of
    # Meteorology pairs with its simplified WBGT)
    def saturation_vapour_pressure(temp_c)
      6.105 * Math.exp(17.27 * temp_c / (237.7 + temp_c))
    end

    # The temperature-and-humidity part of the simplified WBGT (the 3.94
    # constant cancels out when two WBGTs are compared)
    def wbgt_without_constant(temp_c, vapour_hpa)
      (WBGT_TEMPERATURE_COEFFICIENT * temp_c) + (WBGT_VAPOUR_PRESSURE_COEFFICIENT * vapour_hpa)
    end

    # Solves WBGT(x, REFERENCE_HUMIDITY) = WBGT(temp_c, vapour) for x. The left
    # side rises strictly with x, so bisection converges.
    def temperature_at_reference_humidity(temp_c, vapour_hpa)
      target = wbgt_without_constant(temp_c, vapour_hpa)
      low = temp_c - BRACKET_CELSIUS
      high = temp_c + BRACKET_CELSIUS
      BISECTION_STEPS.times do
        mid = (low + high) / 2.0
        reference_wbgt(mid) < target ? low = mid : high = mid
      end
      (low + high) / 2.0
    end

    def reference_wbgt(temp_c)
      wbgt_without_constant(temp_c, REFERENCE_HUMIDITY / 100.0 * saturation_vapour_pressure(temp_c))
    end

    def dew_point_vapour(dew_point_c, temp_c)
      if dew_point_c < MIN_DEW_POINT_CELSIUS
        raise ArgumentError, "dew_point (#{dew_point_c} °C) is below #{MIN_DEW_POINT_CELSIUS} °C"
      end
      if dew_point_c > temp_c
        raise ArgumentError, "dew_point (#{dew_point_c} °C) cannot be above the temperature (#{temp_c} °C)"
      end

      saturation_vapour_pressure(dew_point_c)
    end

    def valid_dew_point?(dew_point)
      dew_point.nil? || finite_number?(dew_point)
    end

    def valid_humidity?(humidity)
      humidity.nil? || (finite_number?(humidity) && humidity.to_f.between?(0.0, 100.0))
    end

    # Real numbers only: Complex is Numeric too, and has no order to compare
    def finite_number?(value)
      value.is_a?(Numeric) && value.real? && value.to_f.finite?
    end
  end
end
