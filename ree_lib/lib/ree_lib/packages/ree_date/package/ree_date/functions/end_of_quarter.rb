# frozen_string_literal: true

class ReeDate::EndOfQuarter
  include Ree::FnDSL

  fn :end_of_quarter do
    link :today
    link :change
    link :days_in_month
  end

  doc(<<~DOC)
    Returns a new date/time at the end of the quarter.
    
      today = Date.today # => Fri, 10 Jul 2015
      today.end_of_quarter # => Wed, 30 Sep 2015
  DOC
  contract(Nilor[Date] => Date)
  def call(date = nil)
    date = date || today
    last_quarter_month = date.month + (12 - date.month) % 3
    last_day = days_in_month(last_quarter_month, date.year)
    change(date, day: last_day, month: last_quarter_month)
  end
end