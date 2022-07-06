# frozen_string_literal: true

class ReeDate::DaysToWeekStart
  include Ree::FnDSL

  fn :days_to_week_start do
    link :today
    link 'ree_date/functions/constants', -> { DAYS_INTO_WEEK }
  end

  doc(<<~DOC)
    Returns the number of days to the start of the week on the given day.
    Week is assumed to start on +start_week_day+.
  DOC
  contract(Nilor[Date], Or[:sunday, :monday] => Integer)
  def call(date = nil, start_week_day)
    date = date || today
    start_day_number = DAYS_INTO_WEEK.fetch(start_week_day)
    (date.wday - start_day_number) % 7
  end
end