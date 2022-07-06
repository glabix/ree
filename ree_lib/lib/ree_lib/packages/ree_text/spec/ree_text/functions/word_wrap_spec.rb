# frozen_string_literal: true

RSpec.describe :word_wrap do
  link :word_wrap, from: :ree_text

  it {
    expect(word_wrap("Once upon a time")).to eq("Once upon a time")

    expect(
      word_wrap(
        "Once upon a time, in a kingdom called Far Far Away, a king fell ill, and finding a successor to the throne turned out to be more trouble than anyone could have imagined..."
      )
    ).to eq(
      "Once upon a time, in a kingdom called Far Far Away, a king fell ill, and finding\na successor to the throne turned out to be more trouble than anyone could have\nimagined..."
    )

    expect(word_wrap("Once upon a time", line_width: 8)).to eq("Once\nupon a\ntime")
    expect(word_wrap("Once upon a time", line_width: 1)).to eq("Once\nupon\na\ntime")
    expect(word_wrap("Once upon a time", line_width: 1, break_sequence: "\r\n")).to eq("Once\r\nupon\r\na\r\ntime")
  }
end