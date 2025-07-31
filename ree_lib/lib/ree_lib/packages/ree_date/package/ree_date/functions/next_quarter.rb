# frozen_string_literal: true

class ReeDate::NextQuarter
  include Ree::FnDSL

  fn :next_quarter do
    link :today
    link :advance_date
  end

  doc("Short-hand for <tt>quarters_since(1)</tt>.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    advance_date(date || today, quarters: 1)
  end
end