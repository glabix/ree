# frozen_string_literal: true

class ReeDate::Constants
  DAYS_INTO_WEEK = {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6
  }

  WEEKEND_DAYS = [ 6, 0 ]

  COMMON_YEAR_DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
end