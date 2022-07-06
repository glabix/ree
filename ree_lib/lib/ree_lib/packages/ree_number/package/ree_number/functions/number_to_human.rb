# frozen_string_literal: true

class ReeNumber::NumberToHuman
  include Ree::FnDSL

  fn :number_to_human do
    link :round_helper, import: -> { ROUND_MODES }
    link :number_to_rounded
    link :slice, from: :ree_hash
    link :t, from: :ree_i18n
    link :number_to_delimited
    link :slice, from: :ree_hash
    link 'ree_number/functions/constants', -> { DECIMAL_UNITS & INVERTED_DECIMAL_UNITS }
  end

  DEFAULTS = {
    units: "decimal_units",
    locale: :en,
    format: "%n %u",
    precision: 3,
    significant: true,
    strip_insignificant_zeros: true,
    separator: ".",
    delimiter: "",
    round_mode: :default
  }.freeze

  doc(<<~DOC)
    Pretty prints (formats and approximates) a number in a way it
    is more readable by humans (e.g.: 1200000000 becomes "1.2
    Billion"). This is useful for numbers that can get very large
    (and too hard to read).
    
    See <tt>number_to_human_size</tt> if you want to print a file
    size.
    
    You can also define your own unit-quantifier names if you want
    to use other decimal units (e.g.: 1500 becomes "1.5
    kilometers", 0.150 becomes "150 milliliters", etc). You may
    define a wide range of unit quantifiers, even fractional ones
    (centi, deci, mili, etc).
    
    ==== Options
    * <tt>:locale</tt> - Sets the locale to be used for formatting
      (defaults to current locale).
    * <tt>:precision</tt> - Sets the precision of the number
      (defaults to 3).
    * <tt>:significant</tt> - If +true+, precision will be the number
      of significant_digits. If +false+, the number of fractional
      digits (defaults to +true+)
    * <tt>:round_mode</tt> - Determine how rounding is performed
      (defaults to :default. See BigDecimal::mode)
    * <tt>:separator</tt> - Sets the separator between the
      fractional and integer digits (defaults to ".").
    * <tt>:delimiter</tt> - Sets the thousands delimiter (defaults
      to "").
    * <tt>:strip_insignificant_zeros</tt> - If +true+ removes
      insignificant zeros after the decimal separator (defaults to
      +true+)
    * <tt>:units</tt> - A Hash of unit quantifier names. Or a
      string containing an i18n scope where to find this hash. It
      might have the following keys:
      * *integers*: <tt>:unit</tt>, <tt>:ten</tt>,
        <tt>:hundred</tt>, <tt>:thousand</tt>, <tt>:million</tt>,
        <tt>:billion</tt>, <tt>:trillion</tt>,
        <tt>:quadrillion</tt>
      * *fractionals*: <tt>:deci</tt>, <tt>:centi</tt>,
        <tt>:mili</tt>, <tt>:micro</tt>, <tt>:nano</tt>,
        <tt>:pico</tt>, <tt>:femto</tt>
    * <tt>:format</tt> - Sets the format of the output string
      (defaults to "%n %u"). The field types are:
      * %u - The quantifier (ex.: 'thousand')
      * %n - The number
    ==== Examples
      number_to_human(123)
      # => "123"

      number_to_human(1234)
      # => "1.23 Thousand"

      number_to_human(12345)
      # => "12.3 Thousand"

      number_to_human(1234567)
      # => "1.23 Million"

      number_to_human(1234567890)
      # => "1.23 Billion"

      number_to_human(1234567890123)
      # => "1.23 Trillion"

      number_to_human(1234567890123456)
      # => "1.23 Quadrillion"

      number_to_human(1234567890123456789)
      # => "1230 Quadrillion"

      number_to_human(489939, precision: 2)
      # => "490 Thousand"

      number_to_human(489939, precision: 4)
      # => "489.9 Thousand"

      number_to_human(1234567, precision: 4, significant: false)
      # => "1.2346 Million"

      number_to_human(1234567, precision: 1, separator: ',', significant: false)
      # => "1,2 Million"
    
      number_to_human(500000000, precision: 5)
      # => "500 Million"

      number_to_human(12345012345, significant: false)
      # => "12.345 Billion"
    
    Non-significant zeros after the decimal separator are stripped
    out by default (set <tt>:strip_insignificant_zeros</tt> to
    +false+ to change that):
    
    number_to_human(12.00001)
    # => "12"

    number_to_human(12.00001, strip_insignificant_zeros: false)
    # => "12.0"
  DOC
  
  contract(
    Or[Integer, Float, String], 
    Ksplat[
      units?: String,
      locale?: Symbol,
      format?: String,
      precision?: Integer,
      significant?: Bool,
      strip_insignificant_zeros?: Bool,
      separator?: String,
      delimiter?: String,
      round_mode?: Or[*ROUND_MODES]
    ] => String
  )
  def call(number, **opts)
    options = DEFAULTS.merge(opts)

    number = round_helper(
      number,
      **slice(options, :precision, :significant, :round_mode)
    )

    number = Float(number)

    exponent = calculate_exponent(
      number, options[:locale], options[:units]
    )

    number = number / (10**exponent)

    rounded_number = number_to_rounded(
      number,
      **slice(
        options,
        :precision, :significant, :strip_insignificant_zeros, :round_mode
      )
    )

    unit = determine_unit(
      exponent, options[:units], options[:locale]
    )

    result_number = options[:format]
      .gsub("%n", rounded_number)
      .gsub("%u", unit)
      .strip

    number_to_delimited(
      result_number,
      **slice(options, :separator, :delimiter)
    )
  end

  private

  def determine_unit(exponent, units, locale)
    exp = DECIMAL_UNITS[exponent]
    case units
    when Hash
      units[exp] || ""
    when String, Symbol
      t("human.#{units}.#{exp}", locale: locale)
    else
      t("human.decimal_units.#{exp}", count: number.to_i)
    end
  end

  def calculate_exponent(number, locale, units)
    exponent = number != 0 ? Math.log10(number.abs).floor : 0
    
    unit_exponents(units, locale).find { |e| exponent >= e } || 0
  end

  def unit_exponents(units, locale)
    case units
    when Hash
      units
    when String, Symbol
      t("human.#{units}", locale: locale, raise: true)
    else
      raise ArgumentError, ":units must be a Hash or String translation scope."
    end.keys.map { |e_name| INVERTED_DECIMAL_UNITS[e_name] }.sort_by(&:-@)
  end
end