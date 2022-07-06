# frozen_string_literal: true

class ReeDatetime::PrevDay
  include Ree::FnDSL

  fn :prev_day do
    link :now
    link :advance
  end

  doc("Short-hand for <tt>days_ago(1)</tt>.")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    advance(date_time || now, days: -1)
  end
end