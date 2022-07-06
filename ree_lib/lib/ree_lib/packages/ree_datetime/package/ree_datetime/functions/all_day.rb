# frozen_string_literal: true

class ReeDatetime::AllDay
  include Ree::FnDSL

  fn :all_day do
    link :now
    link :beginning_of_day
    link :end_of_day
  end

  doc("Returns a Range representing the whole day of the current date/time.")
  contract(Nilor[DateTime] => RangeOf[DateTime])
  def call(date_time = nil)
    date_time = date_time || now
    beginning_of_day(date_time)..end_of_day(date_time)
  end
end