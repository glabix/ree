# frozen_string_literal: true

class ReeDate::BeginningOfQuarter
  include Ree::FnDSL

  fn :beginning_of_quarter do
    link :today
    link :change
    link :beginning_of_month
  end

  doc(<<~DOC)
    Returns a new date at the start of the quarter.
    
      today = Date.today # => Fri, 10 Jul 2015
      today.beginning_of_quarter # => Wed, 01 Jul 2015
  DOC
  contract(Nilor[Date] => Date)
  def call(date = nil)
    date = date || today
    first_quarter_month = date.month - (2 + date.month) % 3

    change(date, day: 1, month: first_quarter_month)
  end
end