# frozen_string_literal: true

class ReeDate::Tuesday
  include Ree::FnDSL

  fn :tuesday do
    link :today 
    link :monday
    link :days_since
  end

  doc("Returns Tuesday of this week assuming that week starts on Monday.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    date = date || today
    days_since(monday(date), 1)
  end
end