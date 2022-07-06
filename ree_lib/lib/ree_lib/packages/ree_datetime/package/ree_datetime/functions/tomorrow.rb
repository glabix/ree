# frozen_string_literal: true

class ReeDatetime::Tomorrow
  include Ree::FnDSL

  fn :tomorrow do
    link :now
    link :advance
  end

  doc("Returns a new date/time representing tomorrow.")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    advance(date_time || now, days: 1)
  end
end