# frozen_string_literal: true

class ReeDatetime::BeginningOfMinute
  include Ree::FnDSL

  fn :beginning_of_minute do
    link :now
    link :change
  end

  doc("Returns a new DateTime representing the start of the minute (ex. 13:15:00).")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    date_time = date_time || now
    change(date_time, sec: 0)
  end
end