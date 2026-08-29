# frozen_string_literal: true

class ReeDate::NextDay
  include Ree::FnDSL

  fn :next_day do
    link :today
    link :advance_date
  end

  doc("# Short-hand for <tt>days_since(1)</tt>.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    advance_date(date || today, days: 1)
  end
end