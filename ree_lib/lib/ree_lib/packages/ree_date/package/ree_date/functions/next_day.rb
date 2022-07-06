# frozen_string_literal: true

class ReeDate::NextDay
  include Ree::FnDSL

  fn :next_day do
    link :today
    link :advance
  end

  doc("# Short-hand for <tt>days_since(1)</tt>.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    advance(date || today, days: 1)
  end
end