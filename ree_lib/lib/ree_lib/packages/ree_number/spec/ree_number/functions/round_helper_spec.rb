# frozen_string_literal: true

RSpec.describe :round_helper do
  link :round_helper, from: :ree_number

  it {
    expect(round_helper(999999)).to be_a(BigDecimal)
  }
end