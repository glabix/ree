# frozen_string_literal: true

class ReeDatetime::IsWeekend
  include Ree::FnDSL

  fn :is_weekend do
    link :now
    link :is_weekend, from: :ree_date
  end

  doc("Returns true if the date/time falls on a Saturday or Sunday.")
  contract(Nilor[DateTime] => Bool)
  def call(date_time = nil)
    is_weekend(date_time || now)
  end
end