# frozen_string_literal: true

class ReeDatetime::Monday
  include Ree::FnDSL

  fn :monday do
    link :now
    link :change
    link :beginning_of_week
  end

  doc("Returns Monday of this week assuming that week starts on Monday.")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    date_time = date_time || now
    change(beginning_of_week(date_time, :monday), hour: date_time.hour, min: date_time.min, sec: date_time.sec)
  end
end