# frozen_string_literal: true

class ReeDate::NextYear
  include Ree::FnDSL

  fn :next_year do
    link :today
    link :advance_date
  end

  doc("Short-hand for <tt>years_since(1)</tt>.")
  contract(Nilor[Date]=> Date)
  def call(date = nil)
    advance_date(date || today, years: 1)
  end
end