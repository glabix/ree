# frozen_string_literal: true

class ReeDate::PrevMonth
  include Ree::FnDSL

  fn :prev_month do
    link :today
    link :advance_date
  end

  doc("Short-hand for <tt>months_ago(1)</tt>.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    advance_date(date || today, months: -1)
  end
end