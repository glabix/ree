# frozen_string_literal: true

class ReeDatetime::QuartersSince
  include Ree::FnDSL

  fn :quarters_since do
    link :now
    link :advance
  end

  doc("Returns a new date/time the specified number of quarters in the future.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, quarter_count)
    advance(date_time || now, quarters: +quarter_count)
  end
end