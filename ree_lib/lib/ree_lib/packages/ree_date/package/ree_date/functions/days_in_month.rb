# frozen_string_literal: true

class ReeDate::DaysInMonth
  include Ree::FnDSL

  fn :days_in_month do
    link :today
    link 'ree_date/functions/constants', -> { COMMON_YEAR_DAYS_IN_MONTH }
  end

  doc(<<~DOC)
    Returns the number of days in the given month.
    If no year is specified, it will use the current year.
  DOC
  contract(Integer, Nilor[Integer] => Integer)
  def call(month, year = nil)
    year = year || today.year

    if month == 2 && Date.gregorian_leap?(year)
      29
    else
      COMMON_YEAR_DAYS_IN_MONTH[month - 1]
    end
  end
end