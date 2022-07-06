# frozen_string_literal: true

class ReeDate::PrevYear
  include Ree::FnDSL

  fn :prev_year do
    link :today
    link :advance
  end

  doc("Short-hand for <tt>years_ago(1)</tt>.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    advance(date || today, years: -1)
  end
end