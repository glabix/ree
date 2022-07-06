# frozen_string_literal: true

class ReeDatetime::BeginningOfHour
  include Ree::FnDSL

  fn :beginning_of_hour do
    link :now
    link :change
  end

  doc("Returns a new DateTime representing the start of the hour (ex. 13:00:00).")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    date_time = date_time || now
    change(date_time, min: 0, sec: 0)
  end
end