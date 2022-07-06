# frozen_string_literal: true

class ReeDatetime::Yesterday
  include Ree::FnDSL

  fn :yesterday do
    link :now
    link :advance
  end

  doc("Returns a new date/time representing yesterday.")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    advance(date_time || now, days: -1)
  end
end