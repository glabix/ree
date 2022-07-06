# frozen_string_literal: true

class ReeDatetime::SecondsAgo
  include Ree::FnDSL

  fn :seconds_ago do
    link :now
    link :seconds_since
  end

  doc("Returns a new date/time the specified number of seconds ago.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, seconds_count)
    date_time  = date_time || now
    seconds_since(date_time, -seconds_count)
  end
end