# frozen_string_literal: true

class ReeDatetime::DaysSince
  include Ree::FnDSL

  fn :days_since do
    link :now
    link :advance
  end

  doc("Returns a new date/time the specified number of days in the future.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, day_count)
    advance(date_time || now, days: +day_count)
  end
end