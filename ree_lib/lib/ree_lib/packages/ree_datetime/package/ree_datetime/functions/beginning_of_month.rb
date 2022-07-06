# frozen_string_literal: true

class ReeDatetime::BeginningOfMonth
  include Ree::FnDSL

  fn :beginning_of_month do
    link :now
    link :beginning_of_day    
    link :beginning_of_month, from: :ree_date
  end

  doc(<<~DOC)
    Returns a new date/time at the start of the month.
    If no date_time passed returns date/time at the start of the current month.
    
      date_time(optional) => Thu, 18 Jun 2015 13:00:00
      beginning_of_month(date_time) # => Mon, 01 Jun 2015 00:00:00
  DOC
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    beginning_of_day(beginning_of_month(date_time || now ).to_datetime) 
  end
end