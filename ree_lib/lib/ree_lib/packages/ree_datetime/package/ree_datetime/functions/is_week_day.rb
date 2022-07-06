# frozen_string_literal: true

class ReeDatetime::IsWeekDay
  include Ree::FnDSL

  fn :is_week_day do
    link :now
    link :is_week_day, from: :ree_date
  end

  doc("Returns true if the date_time/time does not fall on a Saturday or Sunday.")
  contract(Nilor[DateTime] => Bool)
  def call(date_time = nil)
    is_week_day(date_time || now)
  end
end