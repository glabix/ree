# frozen_string_literal: true

RSpec.describe :now do
  link :now, from: :ree_datetime

  it {
    result = now()

    expect(result).to be_a(DateTime)
  }
end