# frozen_string_literal: true

RSpec.describe :truncate_words do
  link :truncate_words, from: :ree_string

  it {
    expect(
      truncate_words('Once upon a time in a world far far away', 4)
    ).to eq("Once upon a time...")

    expect(
      truncate_words('Once<br>upon<br>a<br>time<br>in<br>a<br>world', 5, separator: '<br>')
    ).to eq("Once<br>upon<br>a<br>time<br>in...")

    expect(
      truncate_words('And they found that many people were sleeping better.', 5, omission: '... (continued)')
    ).to eq("And they found that many... (continued)")
  }
end