# frozen_string_literal: true

class ReeDatetime::BeginningOfYear
  include Ree::FnDSL

  fn :beginning_of_year do
    link :now
    link :beginning_of_day    
    link :beginning_of_year, from: :ree_date
  end

  doc(<<~DOC)
    Returns a new date/time at the start of the year.
    If no date_time passed returns date/time at the start of the current year.
    
      date_time(optional) => Mon, 30 Jun 2022 13:00:00
      beginning_of_year(date_time) # => Sat, 01 Jan 2022 00:00:00
  DOC
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    beginning_of_day(beginning_of_year(date_time || now).to_datetime) 
  end
end