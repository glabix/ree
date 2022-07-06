# frozen_string_literal: true

class ReeDate::WeeksSince
  include Ree::FnDSL

  fn :weeks_since do
    link :today
    link :advance
  end

  doc("Returns a new date the specified number of weeks in the future.")
  contract(Nilor[Date], Integer => Date)
  def call(date = nil, week_count)
    advance(date || today, weeks: week_count)
  end
end