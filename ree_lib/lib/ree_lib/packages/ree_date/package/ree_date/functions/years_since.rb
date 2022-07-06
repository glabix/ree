# frozen_string_literal: true

class ReeDate::YearsSince
  include Ree::FnDSL

  fn :years_since do
    link :today
    link :advance
  end

  doc("Returns a new date the specified number of years in the future.")
  contract(Nilor[Date], Integer => Date)
  def call(date = nil, year_count)
    advance(date || today, years: +year_count)
  end
end