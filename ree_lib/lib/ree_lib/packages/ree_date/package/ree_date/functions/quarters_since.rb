# frozen_string_literal: true

class ReeDate::QuartersSince
  include Ree::FnDSL

  fn :quarters_since do
    link :today
    link :advance
  end

  doc("Returns a new date the specified number of quarters in the future.")
  contract(Nilor[Date], Integer => Date)
  def call(date = nil, quarter_count)
    advance(date || today, quarters: +quarter_count)
  end
end