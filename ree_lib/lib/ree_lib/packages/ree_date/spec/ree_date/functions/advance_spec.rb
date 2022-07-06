# frozen_string_literal: true

RSpec.describe :advance do
  link :advance, from: :ree_date

  it {
   result_year_quarter_month_day = advance(Date.new(2005, 2, 28), years: 7, quarters: 1, months: 3, days: 6)
   result_year_quarter_month = advance(Date.new(2005, 2, 28), years: 7, quarters: 1, months: 3)
   result_year_quarter = advance(Date.new(2005, 2, 28), years: 7, quarters: 1) 
   result_day = advance(Date.new(2005, 2, 28), days: 5)
   result_week = advance(Date.new(2005, 2, 28), weeks: 3)
   result_month = advance(Date.new(2005, 6, 28), months: 4)
   result_quarter = advance(Date.new(2006, 10, 28), quarters: 2)
   result_year = advance(Date.new(2006, 2, 28), years: 1)
   result_leap_year = advance(Date.new(2004, 2, 29), years: 1)
   result_year_first = advance(Date.new(2011, 2, 28), years: 1, days: 1)
   result_month_first = advance(Date.new(2010, 2, 28), months: 1, days: 1)

   expect(result_week && result_month && result_quarter && result_year).to be_a(Date)

   expect(result_year).to eq(Date.new(2007, 2, 28))
   expect(result_quarter).to eq(Date.new(2007, 4, 28))
   expect(result_month).to eq(Date.new(2005, 10, 28))
   expect(result_week).to eq(Date.new(2005, 3, 21))
   expect(result_day).to eq(Date.new(2005, 3, 5))
   expect(result_year_quarter).to eq(Date.new(2012, 5, 28))
   expect(result_year_quarter_month).to eq(Date.new(2012, 8, 28))
   expect(result_year_quarter_month_day).to eq(Date.new(2012, 9, 3))
   expect(result_leap_year).to eq(Date.new(2005, 2, 28))
   expect(result_year_first).to eq(Date.new(2012, 2, 29))
   expect(result_month_first).to eq(Date.new(2010, 3, 29))
  }
end