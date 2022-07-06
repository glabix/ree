# frozen_string_literal: true

class ReeDate::AllWeek
  include Ree::FnDSL

  fn :all_week do
    link :today
    link :beginning_of_week
    link :end_of_week
  end

  doc(<<~DOC)
    Returns a Range representing the whole week of the current date.
    Week starts on start_day (sunday or monday).
  DOC
  contract(Nilor[Date], Or[:sunday, :monday] => RangeOf[Date])
  def call(date = nil, start_day)
    date = date || today
    beginning_of_week(date, start_day)..end_of_week(date, start_day)
  end
end