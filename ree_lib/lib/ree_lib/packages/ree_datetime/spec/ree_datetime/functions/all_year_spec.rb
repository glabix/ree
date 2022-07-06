# frozen_string_literal: true

RSpec.describe :all_year do
  link :all_year, from: :ree_datetime

  it {
    result = all_year(DateTime.new(2022, 5, 12, 13, 15, 10))
 
    expect(result).to eq(DateTime.new(2022, 1, 1, 0, 0, 0)..DateTime.new(2022, 12, 31, 23, 59, 59.999999))
   }
 
   it {
     result = all_year()
 
     expect(result).to be_a(Range)
   }
end