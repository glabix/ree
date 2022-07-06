# frozen_string_literal: true

class ReeNumber::NumberToPercentage
  include Ree::FnDSL

  fn :number_to_percentage do
    link :number_to_rounded, import: -> { ROUND_MODES }
    link :slice, from: :ree_hash
  end

  DEFAULTS = {
    format: "%n%",
    precision: 3,
    significant: false,
    strip_insignificant_zeros: false,
    delimiter: "",
    round_mode: :default
  }.freeze

  doc(<<~DOC)
    Converts Integer, String or Float to a String with percentage at the end.
    The +opts+ parameter takes a hash of any of these keys:
        <tt>:format</tt>, <tt>:precision</tt>, 
        <tt>:significant</tt>, <tt>:strip_insignificant_zeros</tt>, <tt>:delimiter</tt>,
        <tt>:round_mode</tt>
      number_to_percentage(100)                                                      # => "100.000%"
      number_to_percentage(123.400, precision: 3, strip_insignificant_zeros: true)   # => "123.4%"
      number_to_percentage.("-0.13", format_percentage: " %", precision: 2)          # => "-0.13 %"
  DOC

  contract(
    Or[Integer, String, Float], 
    Ksplat[
      format?: String, 
      precision?: Integer,
      significant?: Bool,
      strip_insignificant_zeros?: Bool,
      delimiter?: String,
      round_mode?: Or[*ROUND_MODES]
    ] => String
  )
  def call(number, **opts)
    options = DEFAULTS.merge(opts)

    rounded_number = number_to_rounded(
      number,
      **slice(
        options,
        :precision, :significant, :strip_insignificant_zeros, :round_mode
      )
    )

    options[:format].gsub("%n", rounded_number)
  end
end