# frozen_string_literal: true

class ReeDatetime::Tuesday
  include Ree::FnDSL

  fn :tuesday do
    link :now
    link :monday
    link :days_since
  end

  doc("Returns Tuesday of this week assuming that week starts on Monday.")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    date_time = date_time || now
    days_since(monday(date_time), 1)
  end
end