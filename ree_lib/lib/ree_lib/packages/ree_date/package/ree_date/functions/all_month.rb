# frozen_string_literal: true

class ReeDate::AllMonth
  include Ree::FnDSL

  fn :all_month do
    link :today
    link :beginning_of_month
    link :end_of_month
  end

  doc("Returns a Range representing the whole month of the current date.")
  contract(Nilor[Date] => RangeOf[Date])
  def call(date = nil)
    date = date || today
    beginning_of_month(date)..end_of_month(date)
  end
end