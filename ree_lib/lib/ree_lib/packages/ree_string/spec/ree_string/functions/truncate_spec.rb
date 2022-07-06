# frozen_string_literal: true

RSpec.describe :truncate do
  link :truncate, from: :ree_string

  it {
    expect(truncate("Hello World!", 12)).to eq("Hello World!")
    expect(truncate("Hello World!!", 12)).to eq("Hello Wor...")
    expect(truncate("Hello World!", 10, omission: "[...]")).to eq("Hello[...]")
    expect(truncate("Hello Big World!", 13, omission: "[...]", separator: " ")).to eq("Hello[...]")
    expect(truncate("Hello Big World!", 14, omission: "[...]", separator: " ")).to eq("Hello Big[...]")
    expect(truncate("Hello Big World!", 15, omission: "[...]", separator: " ")).to eq("Hello Big[...]")
    expect(truncate("Hello Big World!", 13, omission: "[...]", separator: /\s/)).to eq("Hello[...]")
    expect(truncate("Hello Big World!", 14, omission: "[...]", separator: /\s/)).to eq("Hello Big[...]")
    expect(truncate("Hello Big World!", 15, omission: "[...]", separator: /\s/)).to eq("Hello Big[...]")
    expect(truncate("Hello World!", 12).frozen?).to eq(false)
    expect(truncate("Hello World!!", 12).frozen?).to eq(false)
  }
end