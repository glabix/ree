# frozen_string_literal: true

class ReeDatetime::EndOfYear
  include Ree::FnDSL

  fn :end_of_year do
    link :now
    link :end_of_day    
    link :end_of_year, from: :ree_date
  end

  doc(<<~DOC)
    Returns a new date/time at the start of the year.
    If no date_time passed returns date/time at the start of the current year.
    
      date_time(optional) => Mon, 30 Jun 2022 13:00:00
      end_of_year(date_time) # => Sat, 31 Dec 2022 23:59:59.999999
  DOC
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    end_of_day(end_of_year(date_time || now).to_datetime) 
  end
end