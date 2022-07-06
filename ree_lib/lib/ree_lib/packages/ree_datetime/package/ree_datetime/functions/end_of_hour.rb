# frozen_string_literal: true

class ReeDatetime::EndOfHour
  include Ree::FnDSL

  fn :end_of_hour do
    link :now
    link :change
  end

  doc("Returns a new DateTime representing the end of the hour (ex. 13:59:59).")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    date_time = date_time || now
    change(date_time, min: 59, sec: 59, usec: 999999)
  end
end