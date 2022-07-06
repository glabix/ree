# frozen_string_literal: true

class ReeDatetime::EndOfMinute
  include Ree::FnDSL

  fn :end_of_minute do
    link :now
    link :change
  end

  doc("Returns a new DateTime representing the end of the minute (ex. 13:15:59).")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    date_time = date_time || now
    change(date_time, sec: 59, usec: 999999)
  end
end