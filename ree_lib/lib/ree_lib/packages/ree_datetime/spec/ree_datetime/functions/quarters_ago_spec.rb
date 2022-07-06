# frozen_string_literal: true

RSpec.describe :quarters_ago do
  link :quarters_ago, from: :ree_datetime

  it {
    result = quarters_ago(DateTime.new(2022, 5, 3, 13, 15, 20), 2)

    expect(result).to eq(DateTime.new(2021, 11, 3, 13, 15, 20))
  }

  it {
    result = quarters_ago(2)
    
    expect(result).to be_a(DateTime)
  }
end