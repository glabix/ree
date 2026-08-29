# frozen_string_literal: true

class ReeDate::YearsAgo
  include Ree::FnDSL

  fn :years_ago do
    link :today
    link :advance_date
  end

  doc("Returns a new date the specified number of years ago.")
  contract(Nilor[Date], Integer => Date)
  def call(date = nil, year_count)
    advance_date(date || today, years: -year_count)
  end
end