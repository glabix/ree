# frozen_string_literal: true

class ReeDate::PrevOccurring
  include Ree::FnDSL

  fn :prev_occurring do
    link :today
    link :advance_date
    link :monday
    link :days_since
    link 'ree_date/functions/constants', -> { DAYS_INTO_WEEK }
  end

  doc(<<~DOC)
    Returns a new date representing the previous occurrence of the specified day of week.
    
      today                            # => Tue, 24 May 2022
      date (optional)                  # => Wed, 6  Apr 2022
      prev_occurring(date, :monday)    # => Mon, 28 Mar 2022
      prev_occurring(date, :thursday)  # => Thu, 31 Mar 2022
      prev_occurring(:thursday)        # => Thu, 19 May 2022
  DOC
  contract(Nilor[Date], Or[:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday] => Date)
  def call(date = nil, week_day)
    date = date || today

    days = nil

    if week_day == :sunday
      days = 6
    else
      days = DAYS_INTO_WEEK.fetch(week_day) - 1
    end

    advance_date(date, days: -7)
      .then { monday(_1) }
      .then { days_since(_1, days) }
  end
end