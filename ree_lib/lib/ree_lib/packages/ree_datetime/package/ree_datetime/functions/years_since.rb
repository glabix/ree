# frozen_string_literal: true

class ReeDatetime::YearsSince
  include Ree::FnDSL

  fn :years_since do
    link :now
    link :advance
  end

  doc("Returns a new date/time the specified number of years in the future.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, year_count)
    advance(date_time || now, years: +year_count)
  end
end