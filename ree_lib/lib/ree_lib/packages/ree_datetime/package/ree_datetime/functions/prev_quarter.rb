# frozen_string_literal: true

class ReeDatetime::PrevQuarter
  include Ree::FnDSL

  fn :prev_quarter do
    link :now
    link :advance
  end

  doc("Short-hand for <tt>quarters_ago(1)</tt>.")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    advance(date_time || now, quarters: -1)
  end
end