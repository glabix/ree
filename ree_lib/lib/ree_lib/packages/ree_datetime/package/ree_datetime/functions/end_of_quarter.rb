# frozen_string_literal: true

class ReeDatetime::EndOfQuarter
  include Ree::FnDSL

  fn :end_of_quarter do
    link :now
    link :end_of_day
    link :end_of_quarter, from: :ree_date
  end

  doc(<<~DOC)
    Returns a new date/time at the end of the quarter.
    If no date_time passed returns date/time at the end of the current quarter.
    
      date_time(optional) => Thu, 3 May 2022 13:00:00
      end_of_quarter(date_time) # => Thu, 30 Jun 2022 23:59:59
  DOC
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    end_of_day(
      end_of_quarter(
        (date_time.nil? ? now : date_time).to_date
      ).to_datetime
    )
  end
end