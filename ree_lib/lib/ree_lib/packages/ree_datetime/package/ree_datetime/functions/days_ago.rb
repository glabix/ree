# frozen_string_literal: true

class ReeDatetime::DaysAgo
  include Ree::FnDSL

  fn :days_ago do
    link :now
    link :advance
  end

  doc("Returns a new date/time the specified number of days ago.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, day_count)
    advance(date_time || now, days: -day_count)
  end
end