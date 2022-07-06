# frozen_string_literal: true

class ReeDate::AllQuarter
  include Ree::FnDSL

  fn :all_quarter do
    link :today
    link :beginning_of_quarter
    link :end_of_quarter
  end

  doc("Returns a Range representing the whole quarter of the current date.")
  contract(Nilor[Date] => RangeOf[Date])
  def call(date = nil)
    date = date || today
    beginning_of_quarter(date)..end_of_quarter(date)
  end
end