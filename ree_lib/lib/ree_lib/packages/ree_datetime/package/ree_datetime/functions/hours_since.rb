# frozen_string_literal: true

class ReeDatetime::HoursSince
  include Ree::FnDSL

  fn :hours_since do
    link :now
    link :advance
  end

  doc("Returns a new date/time the specified number of hours in the future.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, hours_count)
    date_time = date_time || now
    advance(date_time, hours: hours_count)
  end
end