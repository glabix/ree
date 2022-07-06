# frozen_string_literal: true

RSpec.describe :truncate_bytes do
  link :truncate_bytes, from: :ree_string

  it {
    expect(truncate_bytes("👍👍👍👍", 16)).to eq("👍👍👍👍")
    expect(truncate_bytes("👍👍👍👍", 16, omission: '')).to eq("👍👍👍👍")
    expect(truncate_bytes("👍👍👍👍", 16, omission: " ")).to eq("👍👍👍👍")
    expect(truncate_bytes("👍👍👍👍", 16, omission: "🖖")).to eq("👍👍👍👍")

    expect(truncate_bytes("👍👍👍👍", 15)).to eq("👍👍👍…")
    expect(truncate_bytes("👍👍👍👍", 15, omission: '')).to eq("👍👍👍")
    expect(truncate_bytes("👍👍👍👍", 15, omission: " ")).to eq("👍👍👍 ")
    expect(truncate_bytes("👍👍👍👍", 15, omission: "🖖")).to eq("👍👍🖖")

    expect(truncate_bytes("👍👍👍👍", 5)).to eq("…")
    expect(truncate_bytes("👍👍👍👍", 5, omission: '')).to eq("👍")
    expect(truncate_bytes("👍👍👍👍", 5, omission: " ")).to eq("👍 ")
    expect(truncate_bytes("👍👍👍👍", 5, omission: "🖖")).to eq("🖖")

    expect(truncate_bytes("👍👍👍👍", 4)).to eq("…")
    expect(truncate_bytes("👍👍👍👍", 4, omission: '')).to eq("👍")
    expect(truncate_bytes("👍👍👍👍", 4, omission: " ")).to eq(" ")
    expect(truncate_bytes("👍👍👍👍", 4, omission: "🖖")).to eq("🖖")

    expect {
      truncate_bytes("👍👍👍👍", 3, omission: "🖖")
    }.to raise_error(ArgumentError)
  }

  it 'preserves grapheme clusters' do
    expect(truncate_bytes("a ❤️ b", 2, omission: '')).to eq("a ")
    expect(truncate_bytes("a ❤️ b", 3, omission: '')).to eq("a ")
    expect(truncate_bytes("a ❤️ b", 7, omission: '')).to eq("a ")
    expect(truncate_bytes("a ❤️ b", 8, omission: '')).to eq("a ❤️")
    expect(truncate_bytes("a 👩‍❤️‍👩", 13, omission: '')).to eq("a ")
    expect(truncate_bytes("👩‍❤️‍👩", 13, omission: '')).to eq("")
  end
end