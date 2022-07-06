# frozen_string_literal: true

class ReeNumber::NumberToPhone
  include Ree::FnDSL

  fn :number_to_phone

  DEFAULT_PHONE_PATTERN = /(\d{0,3})(\d{3})(\d{4})$/
  DEFAULT_AREA_PHONE_PATTERN = /(\d{1,3})(\d{3})(\d{4}$)/

  DEFAULTS = {
    delimiter: "-"
  }.freeze

  doc(<<~DOC)
    Converts Integer to a formatted string (phone number format).
    Country_code, delimiter, area_code, extension are optional.
  
    number_to_phone(5551234)                                     # => "555-1234"
    number_to_phone(8005551212)                                  # => "800-555-1212"
    number_to_phone(8005551212, area_code: true)                 # => "(800) 555-1212"
    number_to_phone(8005551212, delimiter: " ")                  # => "800 555 1212"
    number_to_phone(8005551212, country_code: 7)                 # => "+7-800-555-1212"
    number_to_phone(8005551212, country_code: 7, extension: 123) # => "+7-800-555-1212 x 123"
  DOC
  
  contract(
    Integer, 
    Ksplat[
      country_code?: Integer,
      delimiter?: String,
      area_code?: Bool,
      pattern?: Regexp,
      extension?: Integer
    ] => String
  )
  def call(number, **opts)
    options = DEFAULTS.merge(opts)
    str = country_code(options[:country_code], options[:delimiter]).dup

    str << convert_to_phone_number(
      number.to_s.strip,
      options[:delimiter],
      options[:area_code],
      options[:pattern]
    )

    str << phone_extension(options[:extension]) if options[:extension]
    str
  end

  private 

  def country_code(country_code, delimiter)
    country_code ? "+#{country_code}#{delimiter}" : ""
  end

  def convert_to_phone_number(phone, delimiter, area_code, pattern)
    if area_code
      convert_with_area_code(phone, delimiter, pattern)
    else
      convert_without_area_code(phone, delimiter, pattern)      
    end
  end

  def convert_without_area_code(phone, delimiter, pattern)
    converted_phone = phone.gsub(
      pattern || DEFAULT_PHONE_PATTERN,
      "\\1#{delimiter}\\2#{delimiter}\\3"
    )

    delimiter && converted_phone.start_with?(delimiter) ? converted_phone[1..-1] : converted_phone
  end

  def convert_with_area_code(phone, delimiter, pattern)
    phone.gsub(
      pattern || DEFAULT_AREA_PHONE_PATTERN,
      "(\\1) \\2#{delimiter}\\3"
    )
  end

  def phone_extension(extension)
    " x #{extension}"
  end
end