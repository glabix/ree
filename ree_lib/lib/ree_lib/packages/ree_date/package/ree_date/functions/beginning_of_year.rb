# frozen_string_literal: true

class ReeDate::BeginningOfYear
  include Ree::FnDSL

  fn :beginning_of_year do
    link :today
    link :change
    link :beginning_of_month
  end

  doc(<<~DOC)
    Returns a new date/time at the beginning of the year.
    
      today = Date.today # => Fri, 10 Jul 2015
      today.beginning_of_year # => Thu, 01 Jan 2015
  DOC
  contract(Nilor[Date] => Date)
  def call(date = nil)
    date = date || today
    change(date, day: 1, month: 1)
  end
end