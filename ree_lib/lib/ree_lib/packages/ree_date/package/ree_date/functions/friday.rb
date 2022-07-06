# frozen_string_literal: true

class ReeDate::Friday
  include Ree::FnDSL

  fn :friday do
    link :today 
    link :monday
    link :days_since
  end

  doc("Returns Friday of this week assuming that week starts on Monday.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    date = date || today
    days_since(monday(date), 4)
  end
end