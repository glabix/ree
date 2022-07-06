# frozen_string_literal: true

class ReeDate::EndOfMonth
  include Ree::FnDSL

  fn :end_of_month do
    link :today
    link :days_in_month
    link :change
  end
  
  doc("Returns a new date representing the end of the month.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    date = date || today
    last_day = days_in_month(date.month, date.year)
    change(date, day: last_day)
  end
end