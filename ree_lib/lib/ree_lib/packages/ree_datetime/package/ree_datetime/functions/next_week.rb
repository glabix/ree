# frozen_string_literal: true

class ReeDatetime::NextWeek
  include Ree::FnDSL

  fn :next_week do
    link :now
    link :advance
  end

  doc("Short-hand for <tt>weeks_since(1)</tt>.")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    advance(date_time || now, weeks: 1)
  end
end