# frozen_string_literal: true

class ReeDatetime::HoursAgo
  include Ree::FnDSL

  fn :hours_ago do
    link :now
    link :advance
  end

  doc("Returns a new date_time/time the specified number of hours ago.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, hours_count)
    date_time = date_time || now
    advance(date_time, hours: -hours_count)
  end
end