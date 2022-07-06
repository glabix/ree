# frozen_string_literal: true

class ReeDatetime::Sunday
  include Ree::FnDSL

  fn :sunday do
    link :now
    link :change
    link :end_of_week
    link :beginning_of_day
  end

  doc("Returns Sunday of this week assuming that week starts on Monday.")
  contract(Nilor[DateTime] => DateTime)
  def call(date_time = nil)
    date_time = date_time || now

    change(
      end_of_week(date_time, :monday),
      hour: date_time.hour,
      min: date_time.min,
      sec: date_time.sec
    )
  end
end