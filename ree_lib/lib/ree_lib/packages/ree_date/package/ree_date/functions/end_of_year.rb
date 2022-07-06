# frozen_string_literal: true

class ReeDate::EndOfYear
  include Ree::FnDSL

  fn :end_of_year do
    link :today
    link :change
    link :end_of_month
  end

  doc("Returns a new date representing the end of the year.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    date = date || today
    end_of_month(change(date, month: 12, day: 1)) 
  end
end