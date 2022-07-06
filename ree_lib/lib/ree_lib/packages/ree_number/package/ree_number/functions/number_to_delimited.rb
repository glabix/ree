# frozen_string_literal: true

class ReeNumber::NumberToDelimited
  include Ree::FnDSL

  fn :number_to_delimited

  DEFAULTS = {
    separator: ".",
    delimiter: ",",
    pattern: /(\d)(?=(\d\d\d)+(?!\d))/
  }.freeze

  doc(<<~DOC)
    Converts Integer, Float or String to a String with delimiter.

    number_to_delimited(12345678)
    # => "12,345,678"
    
    number_to_delimited(123456.789)
    # => "123,456.789"

    number_to_delimited(123456.78, pattern: /(\d+?)(?=(\d\d)+(\d)(?!\d))/))
    # => "1,23,456.78"
  DOC
  
  contract(
    Or[Integer, Float, String], 
    Ksplat[
      separator?: String, 
      delimiter?: String, 
      pattern?: Regexp
    ] => String
  )
  def call(number, **opts)
    options = DEFAULTS.merge(opts)
    left, right = number.to_s.split(".")
    
    delimited_left = left.gsub(options[:pattern] || options[:pattern]) do |digit_to_delimit|
      "#{digit_to_delimit}#{options[:delimiter]}"
    end

    [delimited_left, right].compact.join(options[:separator])
  end
end