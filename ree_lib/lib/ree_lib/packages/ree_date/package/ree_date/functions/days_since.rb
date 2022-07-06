# frozen_string_literal: true

class ReeDate::DaysSince
  include Ree::FnDSL

  fn :days_since do
    link :today
    link :advance
  end

  doc("Returns a new date the specified number of days in the future.")
  contract(Nilor[Date], Integer => Date)
  def call(date = nil, day_count)
    advance(date || today, days: +day_count)
  end
end