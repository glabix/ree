# frozen_string_literal: true

class ReeNumber::NumberToCurrency
  include Ree::FnDSL

  fn :number_to_currency do
    link :number_to_rounded, import: -> { ROUND_MODES}
    link :number_to_delimited
    link :slice, from: :ree_hash
  end

  DEFAULTS = {
    format: "%u%n",
    negative_format: "-%u%n",
    unit: "$",
    separator: ".",
    delimiter: ",",
    precision: 2,
    significant: false,
    strip_insignificant_zeros: false,
    round_mode: :default
  }.freeze

  doc(<<~DOC)
    Converts Integer, Float or String to a String with currency sign and delimiters.
      number_to_currency(1234567890.506)
      # => "$1,234,567,890.51"

      number_to_currency(-1234567890.50)
      # => "-$1,234,567,890.50"

      number_to_currency(1234567890.50, unit: "&pound")
      # => "&pound1,234,567,890.50"
      
      number_to_currency(1234567890.50, unit: "&pound;", separator: ",", delimiter: "")
      # => "&pound;1234567890,50"
  DOC

  contract(
    Or[Integer, Float, String], 
    Ksplat[
      format?: String, 
      precision?: Integer, 
      unit?: String, 
      negative_format?: String,
      separator?: String,
      delimiter?: String,
      significant?: Bool,
      strip_insignificant_zeros?: Bool,
      round_mode?: Or[*ROUND_MODES]
    ] => String
  )
  def call(number, **opts)
    options = DEFAULTS.dup
    options[:negative_format] = "-#{opts[:format]}" if opts[:format]
    options.merge!(opts)
    number_f = Float(number, exception: false)

    if number_f
      if number_f.negative?
        number_f = number_f.abs
        options[:format] = options[:negative_format] if (number_f * 10**options[:precision]) >= 0.5
      end

      number_s = number_to_delimited(
        number_to_rounded(
          number_f, 
          **slice(options, :precision, :significant, :strip_insignificant_zeros, :round_mode)
        ),
        **slice(options, :delimiter, :separator)
      )
    else
      number_s = number.to_s.strip
      options[:format] = options[:negative_format] if number_s.sub!(/^-/, "")
    end

    options[:format].gsub("%n", number_s).gsub("%u", options[:unit])
  end  
end