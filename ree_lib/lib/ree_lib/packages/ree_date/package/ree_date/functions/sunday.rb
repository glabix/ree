# frozen_string_literal: true

class ReeDate::Sunday
  include Ree::FnDSL

  fn :sunday do
    link :today
    link :end_of_week
  end

  doc("Returns Sunday of this week assuming that week starts on Monday.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    date = date || today
    end_of_week(date, :monday)
  end
end