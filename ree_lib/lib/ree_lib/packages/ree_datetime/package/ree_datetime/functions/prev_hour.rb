# frozen_string_literal: true

class ReeDatetime::PrevHour
  include Ree::FnDSL

  fn :prev_hour do
    link :now
    link :advance
  end

  doc("Short-hand for <tt>hours_ago(1)</tt>.")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    advance(date_time || now, hours: -1)
  end
end