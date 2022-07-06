# frozen_string_literal: true

class ReeDate::BeginningOfMonth
  include Ree::FnDSL

  fn :beginning_of_month do
    link :today
    link :change
  end

  doc(<<~DOC)
    Returns a new date at the start of the month.
    
      today = Date.today # => Thu, 18 Jun 2015
      today.beginning_of_month # => Mon, 01 Jun 2015
  DOC
  contract(Nilor[Date] => Date)
  def call(date = nil)
    change(date || today, day: 1)
  end
end