# frozen_string_literal: true

class ReeNumber::NumberToHumanSize
  include Ree::FnDSL

  fn :number_to_human_size do
    link :number_to_rounded, import: -> { ROUND_MODES }
    link :slice, from: :ree_hash
    link :t, from: :ree_i18n
    link :number_to_delimited
    link 'ree_number/functions/constants', -> { STORAGE_UNITS }
  end

  DEFAULTS = {
    locale: :en,
    format: "%n %u",
    precision: 3,
    significant: true,
    strip_insignificant_zeros: true,
    separator: ".",
    delimiter: "",
    round_mode: :default
  }.freeze

  BASE = 1024

  doc(<<~DOC)
    Formats the bytes in +number+ into a more understandable
    representation (e.g., giving it 1500 yields 1.46 KB). This
    method is useful for reporting file sizes to users. You can
    customize the format in the +options+ hash.

    See <tt>number_to_human</tt> if you want to pretty-print a
    generic number.

    ==== Options

    * <tt>:locale</tt> - Sets the locale to be used for formatting
      (defaults to current locale).
    * <tt>:precision</tt> - Sets the precision of the number
      (defaults to 3).
    * <tt>:round_mode</tt> - Determine how rounding is performed
      (defaults to :default. See BigDecimal::mode)
    * <tt>:significant</tt> - If +true+, precision will be the number
      of significant_digits. If +false+, the number of fractional
      digits (defaults to +true+)
    * <tt>:separator</tt> - Sets the separator between the
      fractional and integer digits (defaults to ".").
    * <tt>:delimiter</tt> - Sets the thousands delimiter (defaults
      to "").
    * <tt>:strip_insignificant_zeros</tt> - If +true+ removes
      insignificant zeros after the decimal separator (defaults to
      +true+)
    ==== Examples
      number_to_human_size(123)
      # => "123 Bytes"

      number_to_human_size(1234)
      # => "1.21 KB"

      number_to_human_size(12345)
      # => "12.1 KB"

      number_to_human_size(1234567)
      # => "1.18 MB"

      number_to_human_size(1234567890)
      # => "1.15 GB"

      number_to_human_size(1234567890123)
      # => "1.12 TB"

      number_to_human_size(1234567890123456)
      # => "1.1 PB"

      number_to_human_size(1234567890123456789)
      # => "1.07 EB"

      number_to_human_size(1234567, precision: 2)
      # => "1.2 MB"

      number_to_human_size(483989, precision: 2)
      # => "470 KB"

      number_to_human_size(483989, precision: 2, round_mode: :up)
      # => "480 KB"

      number_to_human_size(1234567, precision: 2, separator: ',')
      # => "1,2 MB"

      number_to_human_size(1234567890123, precision: 5)
      # => "1.1228 TB"

      number_to_human_size(524288000, precision: 5)
      # => "500 MB"
  DOC

  contract(
    Or[Integer, Float, String],
    Ksplat[
      locale?: Symbol,
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

    number = Float(number)

    if smaller_than_base?(number)
      number_to_format = number.to_i.to_s
    else
      human_size = number / (BASE**exponent(number))
      number_to_format = number_to_rounded(
        human_size,
        **slice(
          options,
          [:precision, :significant, :strip_insignificant_zeros, :round_mode]
        )
      )
    end

    storage_unit_key = storage_unit_key(number)

    unit = unit(options[:locale], storage_unit_key, number)
    result_number = options[:format]
      .gsub("%n", number_to_format)
      .gsub("%u", unit)

    number_to_delimited(
      result_number,
      **slice(options, [:separator, :delimiter])
    )
  end

  private

  def unit(locale, storage_unit_key, number)
    t(
      storage_unit_key,
      locale: locale,
      count: number.to_i,
      raise: true,
      default_by_locale: :en
    )
  end

  def storage_unit_key(number)
    key_end = smaller_than_base?(number) ? "byte" : STORAGE_UNITS[exponent(number)]
    "human.sizes.#{key_end}"
  end

  def exponent(number)
    max = STORAGE_UNITS.size - 1
    exp = (Math.log(number) / Math.log(BASE)).to_i
    exp = max if exp > max
    exp
  end

  def smaller_than_base?(number)
    number.to_i < BASE
  end
end