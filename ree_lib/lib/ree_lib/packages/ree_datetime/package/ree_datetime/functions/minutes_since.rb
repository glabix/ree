# frozen_string_literal: true

class ReeDatetime::MinutesSince
  include Ree::FnDSL

  fn :minutes_since do
    link :now
    link :advance
  end

  doc("Returns a new date/time the specified number of minutes in the future.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, minutes_count)
    date_time = date_time || now
    advance(date_time, minutes: minutes_count)
  end
end