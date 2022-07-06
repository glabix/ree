# frozen_string_literal: true

class ReeDatetime::WeeksAgo
  include Ree::FnDSL

  fn :weeks_ago do
    link :now
    link :advance
  end

  doc("Returns a new date/time the specified number of weeks ago.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, week_count)
    advance(date_time || now, weeks: -week_count)
  end
end