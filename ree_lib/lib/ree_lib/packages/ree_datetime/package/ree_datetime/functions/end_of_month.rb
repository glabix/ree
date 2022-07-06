# frozen_string_literal: true

class ReeDatetime::EndOfMonth
  include Ree::FnDSL

  fn :end_of_month do
    link :now
    link :change
    link :end_of_day
    link :end_of_month, from: :ree_date
  end

  doc(<<~DOC)
    Returns a new date/time at the end of the month.
    If no date_time passed returns date/time at the end of the current month.
    
      date_time(optional) => Thu, 18 Jun 2015 13:00:00
      end_of_month(date_time) # => Mon, 30 Jun 2015 23:59:59.999999
  DOC
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    end_of_day(
      end_of_month(date_time || now).to_datetime
    ) 
  end
end