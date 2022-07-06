# frozen_string_literal: true

class ReeDatetime::NextHour
  include Ree::FnDSL

  fn :next_hour do
    link :now
    link :advance
  end

  doc("Short-hand for <tt>hours_since(1)</tt>.")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    advance(date_time || now, hours: 1)
  end
end