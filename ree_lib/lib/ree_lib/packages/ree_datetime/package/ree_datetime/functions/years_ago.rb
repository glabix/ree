# frozen_string_literal: true

class ReeDatetime::YearsAgo
  include Ree::FnDSL

  fn :years_ago do
    link :now
    link :advance
  end

  doc("Returns a new date/time the specified number of years ago.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, year_count)
    advance(date_time || now, years: -year_count)
  end
end