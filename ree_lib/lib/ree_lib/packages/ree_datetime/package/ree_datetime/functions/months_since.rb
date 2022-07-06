# frozen_string_literal: true

class ReeDatetime::MonthsSince
  include Ree::FnDSL

  fn :months_since do
    link :now
    link :advance
  end

  doc("Returns a new date/time the specified number of months in the future.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, month_count)
    advance(date_time || now, months: month_count)
  end
end