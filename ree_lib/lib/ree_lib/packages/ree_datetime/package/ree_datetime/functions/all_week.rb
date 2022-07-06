# frozen_string_literal: true

class ReeDatetime::AllWeek
  include Ree::FnDSL

  fn :all_week do
    link :now
    link :beginning_of_week
    link :end_of_week
  end

  doc(<<~DOC)
    Returns a Range representing the whole week of the current date/time.
    If no date_time passed returns the whole current week.
    Week is assumed to start on +week_start+ (monday or sunday).
  DOC
  contract(Nilor[DateTime], Or[:sunday, :monday] => RangeOf[DateTime])
  def call(date_time = nil, start_day)
    date_time = date_time || now
    beginning_of_week(date_time, start_day)..end_of_week(date_time, start_day)
  end
end