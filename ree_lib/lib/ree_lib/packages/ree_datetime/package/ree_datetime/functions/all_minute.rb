# frozen_string_literal: true

class ReeDatetime::AllMinute
  include Ree::FnDSL

  fn :all_minute do
    link :now
    link :beginning_of_minute
    link :end_of_minute
  end

  doc("Returns a Range representing the whole minute of the current date/time.")
  contract(Nilor[DateTime] => RangeOf[DateTime])
  def call(date_time = nil)
    date_time = date_time || now
    beginning_of_minute(date_time)..end_of_minute(date_time)
  end
end