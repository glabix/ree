# frozen_string_literal: true

class ReeNumber::DigitCount
  include Ree::FnDSL

  fn :digit_count

  doc("Counts number of integers.")
  contract(Or[Integer, Float, BigDecimal] => Integer)
  def call(number)
    return 1 if number.zero?
    (Math.log10(number.abs) + 1).floor
  end
end