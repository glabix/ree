# frozen_string_literal: true

class ReeDatetime::PrevMonth
  include Ree::FnDSL

  fn :prev_month do
    link :now
    link :advance
  end

  doc("Short-hand for <tt>months_ago(1)</tt>.")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    advance(date_time || now, months: -1)
  end
end