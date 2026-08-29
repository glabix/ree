# frozen_string_literal: true

class ReeDate::PrevDay
  include Ree::FnDSL

  fn :prev_day do
    link :today
    link :advance_date
  end

  doc("Short-hand for <tt>days_ago(1)</tt>.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    advance_date(date || today, days: -1)
  end
end