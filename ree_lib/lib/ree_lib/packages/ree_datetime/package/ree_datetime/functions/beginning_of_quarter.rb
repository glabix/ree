# frozen_string_literal: true

class ReeDatetime::BeginningOfQuarter
  include Ree::FnDSL

  fn :beginning_of_quarter do
    link :now
    link :beginning_of_day
    link :beginning_of_quarter, from: :ree_date
  end

  doc(<<~DOC)
    Returns a new date/time at the start of the quarter.
    If no date_timetime passed returns date/time at the start of the current quarter.
    
      date_time(optional) => Thu, 3 May 2022 13:00:00
      beginning_of_quarter(date_time) # => Fri, 01 Apr 2022 00:00:00
  DOC
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    beginning_of_day(beginning_of_quarter(date_time || now).to_datetime)
  end
end