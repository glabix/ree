# frozen_string_literal: true

class ReeDatetime::NextYear
  include Ree::FnDSL

  fn :next_year do
    link :now
    link :advance
  end

  doc("Short-hand for <tt>years_since(1)</tt>.")
  contract(Nilor[DateTime]=> DateTime)
  def call(date_time = nil)
    advance(date_time || now, years: 1)
  end
end