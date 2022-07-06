# frozen_string_literal: true

class ReeDatetime::PrevWeek
  include Ree::FnDSL

  fn :prev_week do
    link :now
    link :advance
  end

  doc("Short-hand for <tt>weeks_ago(1)</tt>.")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    advance(date_time || now, weeks: -1)
  end
end