# frozen_string_literal: true

class ReeDate::WeeksAgo
  include Ree::FnDSL

  fn :weeks_ago do
    link :today
    link :advance_date
  end

  doc("Returns a new date the specified number of weeks ago.")
  contract(Nilor[Date], Integer => Date)
  def call(date = nil, week_count)
    advance_date(date || today, weeks: -week_count)
  end
end