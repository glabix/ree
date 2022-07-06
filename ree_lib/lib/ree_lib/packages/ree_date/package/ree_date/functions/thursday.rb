# frozen_string_literal: true

class ReeDate::Thursday
  include Ree::FnDSL

  fn :thursday do
    link :today 
    link :monday
    link :days_since
  end

  doc("Returns Thursday of this week assuming that week starts on Monday.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    date = date || today
    days_since(monday(date), 3)
  end
end