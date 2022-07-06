# frozen_string_literal: true

class ReeDatetime::NextQuarter
  include Ree::FnDSL

  fn :next_quarter do
    link :now
    link :advance
  end

  doc("Short-hand for <tt>quarters_since(1)</tt>.")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    advance(date_time || now, quarters: 1)
  end
end