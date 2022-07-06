# frozen_string_literal: true

class ReeDatetime::NextDay
  include Ree::FnDSL

  fn :next_day do
    link :now
    link :advance
  end

  doc("Short-hand for <tt>days_since(1)</tt>.")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    advance(date_time || now, days: 1)
  end
end