# frozen_string_literal: true

class ReeDatetime::AllHour
  include Ree::FnDSL

  fn :all_hour do
    link :now
    link :beginning_of_hour
    link :end_of_hour
  end

  doc("Returns a Range representing the whole hour of the current date/time.")
  contract(Nilor[DateTime] => RangeOf[DateTime])
  def call(date_time = nil)
    date_time = date_time || now
    beginning_of_hour(date_time)..end_of_hour(date_time)
  end
end