# frozen_string_literal: true

class ReeDate::EndOfWeek
  include Ree::FnDSL

  fn :end_of_week do
    link :today
    link :days_since
    link :days_to_week_start
  end

  doc(<<~DOC)
    Returns a new date at the end of the week.
    If no date passed returns date at the end of the current week.
    
      date(optional) => Wed, 25 May 2022
      end_of_week(date, :monday) # => Sun, 29 May 2022
      end_of_week(date, :sunday) # => Sat, 28 May 2022
    Week is assumed to end on +week_start+ (monday or sunday).
  DOC
  contract(Nilor[Date], Or[:sunday, :monday] => Date)
  def call(date = nil, week_start)
    date = date || today
    days_since(date, 6 - days_to_week_start(date, week_start))
  end
end