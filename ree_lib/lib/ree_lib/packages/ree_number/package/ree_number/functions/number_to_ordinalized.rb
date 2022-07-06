# frozen_string_literal: true

class ReeNumber::NumberToOrdinalized
  include Ree::FnDSL

  fn :number_to_ordinalized do
    link :t, from: :ree_i18n
  end

  DEFAULTS = {
    locale: :en
  }

  doc(<<~DOC)
    Turns a number into an ordinal string used to denote the position in an
    ordered sequence such as 1st, 2nd, 3rd, 4th.
   
      ordinalize(1)     # => "1st"
      ordinalize(2)     # => "2nd"
      ordinalize(1002)  # => "1002nd"
      ordinalize(1003)  # => "1003rd"
      ordinalize(-11)   # => "-11th"
      ordinalize(-1021) # => "-1021st"
  DOC

  contract(
    Integer,
    Ksplat[locale?: Symbol] => String
  )
  def call(number, **opts)
    options = DEFAULTS.merge(opts)
    ordinalize(number, options[:locale])
  end

  private

  # Returns the suffix that should be added to a number to denote the position
  # in an ordered sequence such as 1st, 2nd, 3rd, 4th.
  #
  #   ordinal(1)     # => "st"
  #   ordinal(2)     # => "nd"
  #   ordinal(1002)  # => "nd"
  #   ordinal(1003)  # => "rd"
  #   ordinal(-11)   # => "th"
  #   ordinal(-1021) # => "st"
  def ordinal(number, locale)
    number = number.abs
    number_key = number % 100

    if number_key > 13
      number_key %= 10
    end

    t("human.ordinals.#{number_key}", locale: locale)
  end

  def ordinalize(number, locale)
    number.to_s + ordinal(number, locale)
  end
end
