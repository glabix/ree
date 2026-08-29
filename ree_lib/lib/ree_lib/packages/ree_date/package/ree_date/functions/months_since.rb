# frozen_string_literal: true

class ReeDate::MonthsSince
  include Ree::FnDSL

  fn :months_since do
    link :today
    link :advance_date
  end

  doc("Returns a new date the specified number of months in the future.")
  contract(Nilor[Date], Integer => Date)
  def call(date = nil , month_count)
    advance_date(date || today, months: +month_count)
  end
end