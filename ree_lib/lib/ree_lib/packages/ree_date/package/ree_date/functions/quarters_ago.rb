# frozen_string_literal: true

class ReeDate::QuartersAgo
  include Ree::FnDSL

  fn :quarters_ago do
    link :today
    link :advance_date
  end

  doc("Returns a new date the specified number of quarters ago.")
  contract(Nilor[Date], Integer => Date)
  def call(date = nil, quarter_count)
    advance_date(date || today, quarters: -quarter_count)
  end
end