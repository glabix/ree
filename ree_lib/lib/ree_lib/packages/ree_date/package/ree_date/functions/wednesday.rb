# frozen_string_literal: true

class ReeDate::Wednesday
  include Ree::FnDSL

  fn :wednesday do
    link :today 
    link :monday
    link :days_since
  end

  doc("Returns Wednesday of this week assuming that week starts on Monday.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    date = date || today
    days_since(monday(date), 2)
  end
end