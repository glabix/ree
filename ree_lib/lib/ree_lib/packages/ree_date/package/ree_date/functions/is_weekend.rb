# frozen_string_literal: true

class ReeDate::IsWeekend
  include Ree::FnDSL

  fn :is_weekend do
    link :today
    link 'ree_date/functions/constants', -> { WEEKEND_DAYS } 
  end

  doc("Returns true if the date falls on a Saturday or Sunday.")
  contract(Nilor[Date] => Bool)
  def call(date = nil)
    date = date || today
    WEEKEND_DAYS.include?(date.wday)
  end
end