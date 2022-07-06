# frozen_string_literal: true

class ReeNumber::RoundHelper
  include Ree::FnDSL

  fn :round_helper do
    link :digit_count
  end

  ROUND_MODES = [
    :up, # round away from zero
    :down, # round towards zero (truncate)
    :truncate, # round towards zero (truncate)
    :half_up, # round towards the nearest neighbor, unless both neighbors are equidistant, in which case round away from zero. (default)
    :default, # round towards the nearest neighbor, unless both neighbors are equidistant, in which case round away from zero. (default)
    :half_down, # round towards the nearest neighbor, unless both neighbors are equidistant, in which case round towards zero.
    :half_even, # round towards the nearest neighbor, unless both neighbors are equidistant, in which case round towards the even neighbor (Banker's rounding)
    :banker, # round towards the nearest neighbor, unless both neighbors are equidistant, in which case round towards the even neighbor (Banker's rounding)
    :ceiling, # round towards positive infinity (ceil)
    :floor, # round towards negative infinity (floor)
  ]
  
  DEFAULTS = {
    precision: 3,
    significant: false,
    round_mode: :default
  }.freeze

  contract(
    Or[Integer, Float, Rational, String], 
    Ksplat[
      precision?: Integer,
      significant?: Bool,
      round_mode?: Or[*ROUND_MODES]
    ] => Or[Integer, BigDecimal]
  )
  def call(number, **opts)
    options = DEFAULTS.merge(opts)

    absolute_precision = absolute_precision(
      number, options[:significant], options[:precision]
    )

    rounded_number = convert_to_decimal(number, options[:precision]).round(absolute_precision, options[:round_mode])

    rounded_number = rounded_number.zero? ? rounded_number.abs : rounded_number
  end

  private

  def absolute_precision(number, significant, precision)
    if significant && precision > 0
      precision - digit_count(convert_to_decimal(number, precision))
    else
      precision
    end
  end

  def convert_to_decimal(number, precision)
    case number
    when Float, String, Integer
      BigDecimal(number.to_s)
    when Rational
      BigDecimal(number, digit_count(number.to_i) + precision)
    else
      number.to_d
    end
  end
end