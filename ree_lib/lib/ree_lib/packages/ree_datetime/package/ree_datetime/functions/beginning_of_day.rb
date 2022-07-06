# frozen_string_literal: true

class ReeDatetime::BeginningOfDay
  include Ree::FnDSL

  fn :beginning_of_day do
    link :now
    link :change
  end

  doc("Returns a new DateTime representing the start of the day (0:00).")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    date_time = date_time || now
    change(date_time, hour: 0, min: 0, sec: 0)
  end
end