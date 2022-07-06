# frozen_string_literal: true

class ReeDatetime::EndOfDay
  include Ree::FnDSL

  fn :end_of_day do
    link :now
    link :change
  end

  doc("Returns a new DateTime representing the end of the day (23:59:59).")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    date_time = date_time || now
    change(date_time, hour: 23, min: 59, sec: 59, usec: 999999)
  end
end