# frozen_string_literal: true

class ReeDatetime::QuartersAgo
  include Ree::FnDSL

  fn :quarters_ago do
    link :now
    link :advance
  end

  doc("Returns a new date/time the specified number of quarters ago.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, quarter_count)
    advance(date_time || now, quarters: -quarter_count)
  end
end