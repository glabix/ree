# frozen_string_literal: true

class ReeDate::BeginningOfWeek
  include Ree::FnDSL

  fn :beginning_of_week do
    link :today
    link :days_ago
    link :days_to_week_start
  end

  doc(<<~DOC)
    Returns a new date representing the start of this week on the given day.
    Week is assumed to start on +week_start+, default is monday.
  DOC
  contract(Nilor[Date], Or[:sunday, :monday] => Date)
  def call(date = nil, week_start)
    date = date || today
    days_ago(date, days_to_week_start(date, week_start))
  end
end
