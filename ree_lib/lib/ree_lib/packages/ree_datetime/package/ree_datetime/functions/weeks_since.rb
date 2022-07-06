# frozen_string_literal: true

class ReeDatetime::WeeksSince
  include Ree::FnDSL

  fn :weeks_since do
    link :now
    link :advance
  end

  doc("Returns a new date_time/time the specified number of weeks in the future.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, week_count)
    advance(date_time || now, weeks: week_count)
  end
end