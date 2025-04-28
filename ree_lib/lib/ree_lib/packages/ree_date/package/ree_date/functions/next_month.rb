# frozen_string_literal: true

class ReeDate::NextMonth
  include Ree::FnDSL

  fn :next_month do
    link :today
    link :advance_date
  end

  doc("Short-hand for <tt>months_since(1)</tt>.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    advance_date(date || today, months: 1)
  end
end