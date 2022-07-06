# frozen_string_literal: true

class ReeDate::Saturday
  include Ree::FnDSL

  fn :saturday do
    link :today 
    link :monday
    link :days_since
  end

  doc("Returns Saturday of this week assuming that week starts on Monday.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    date = date || today
    days_since(monday(date), 5)
  end
end