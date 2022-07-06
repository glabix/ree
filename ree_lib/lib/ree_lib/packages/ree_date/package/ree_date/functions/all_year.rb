# frozen_string_literal: true

class ReeDate::AllYear
  include Ree::FnDSL

  fn :all_year do
    link :today
    link :beginning_of_year
    link :end_of_year
  end

  doc("Returns a Range representing the whole year of the current date.")
  contract(Nilor[Date] => RangeOf[Date])
  def call(date = nil)
    date = date || today
    beginning_of_year(date)..end_of_year(date)
  end
end