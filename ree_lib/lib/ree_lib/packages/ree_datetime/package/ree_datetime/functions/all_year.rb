# frozen_string_literal: true

class ReeDatetime::AllYear
  include Ree::FnDSL

  fn :all_year do
    link :now
    link :beginning_of_year
    link :end_of_year
  end

  doc(<<~DOC)
    Returns a Range representing the whole year of the current date/time.
    If no date_time passed returns the whole current year.
  DOC
  contract(Nilor[DateTime] => RangeOf[DateTime])
  def call(date_time = nil)
    date_time = date_time || now
    beginning_of_year(date_time)..end_of_year(date_time)
  end
end