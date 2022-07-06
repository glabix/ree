# frozen_string_literal: true

class ReeDate::IsWeekDay
  include Ree::FnDSL

  fn :is_week_day do
    link :today
    link 'ree_date/functions/constants', -> { WEEKEND_DAYS } 
  end

  doc("Returns true if the date does not fall on a Saturday or Sunday.")
  contract(Nilor[Date] => Bool)
  def call(date = nil)
    date = date || today
    !WEEKEND_DAYS.include?(date.wday)
  end
end