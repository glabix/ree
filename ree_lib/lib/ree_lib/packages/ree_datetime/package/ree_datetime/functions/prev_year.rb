# frozen_string_literal: true

class ReeDatetime::PrevYear
  include Ree::FnDSL

  fn :prev_year do
    link :now
    link :advance
  end

  doc("Short-hand for <tt>years_ago(1)</tt>.")
  contract(Nilor[DateTime]=> DateTime)
  def call(date_time = nil)
    advance(date_time || now, years: -1)
  end
end