# frozen_string_literal: true

class ReeDatetime::MonthsAgo
  include Ree::FnDSL

  fn :months_ago do
    link :now
    link :advance
  end

  doc("Returns a new date_time/time the specified number of months ago.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, month_count)
    advance(date_time || now, months: -month_count)
  end
end