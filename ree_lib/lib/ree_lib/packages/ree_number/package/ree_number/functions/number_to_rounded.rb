# frozen_string_literal: true

class ReeNumber::NumberToRounded
  include Ree::FnDSL

  fn :number_to_rounded do
    link :number_to_delimited
    link :digit_count
    link :round_helper, import: -> { ROUND_MODES }
    link :slice, from: :ree_hash
  end

  DEFAULTS = {
    precision: 3,
    significant: false,
    strip_insignificant_zeros: false,
    delimiter: "",
    round_mode: :default
  }.freeze

  doc(<<~DOC)
    Rounds Integer(Float, Rational, String) and converts to a String.

    The +options+ parameter takes a hash of any of these keys: 
      <tt>:precision</tt>, <tt>:significant</tt>, <tt>:strip_insignificant_zeros</tt>.

    Presicion is 3 by default.
      number_to_rounded(111.2346)                                # => "111.235"
      number_to_rounded("111.2346")                              # => "111.235"
      number_to_rounded("111.2346", precision: 20)               # => "111.23460000000000000000"
      number_to_rounded(Rational(1112346, 10000)                 # => "111.2346"
      number_to_rounded(123987, precision: 3, significant: true) # => "124000"

      number_to_rounded(
        5.3929, 
        precision: 10, 
        significant: true, 
        strip_insignificant_zeros: true
      )                                                          # => "5.3929"
  DOC
  
  contract(
    Or[Integer, Float, Rational, String], 
    Ksplat[
      precision?: Integer,
      significant?: Bool,
      strip_insignificant_zeros?: Bool,
      round_mode?: Or[*ROUND_MODES]
    ] => String
  )
  def call(number, **opts)
    options = DEFAULTS.merge(opts)

    rounded_number = round_helper(
      number, 
      **slice(
        options, 
        [:precision, :significant, :round_mode]
      )
    )

    if precision = options[:precision]

      if options[:significant] && precision > 0
        digits = digit_count(rounded_number)
        precision -= digits
        precision = 0 if precision < 0
      end

      formatted_string = 

        if rounded_number.finite?
          s = rounded_number.to_s("F")
          a, b = s.to_s.split(".", 2)

          if precision != 0
            b << "0" * precision
            a << "."
            a << b[0, precision]
          end
          a
        else 
          "%f" % rounded_number
        end

    else 
      formatted_string = rounded_number
    end

    delimited_number = number_to_delimited(formatted_string, **slice(options, [:separator, :delimiter]))
    options[:strip_insignificant_zeros] ? format_number(delimited_number) : delimited_number
  end

  private

  def format_number(number)
    escaped_separator = Regexp.escape(".")
    number.sub(/(#{escaped_separator})(\d*[1-9])?0+\z/, '\1\2').sub(/#{escaped_separator}\z/, "")      
  end
end