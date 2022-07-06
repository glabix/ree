# frozen_string_literal: true

class ReeDate::Monday
  include Ree::FnDSL

  fn :monday do
    link :today
    link :beginning_of_week
  end

  doc("Returns Monday of this week assuming that week starts on Monday.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    date = date || today
    beginning_of_week(date, :monday)
  end
end