# frozen_string_literal: true

class ReeDate::PrevWeek
  include Ree::FnDSL

  fn :prev_week do
    link :today
    link :advance
  end

  doc("Short-hand for <tt>weeks_ago(1)</tt>.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    advance(date || today, weeks: -1)
  end
end