# frozen_string_literal: true

RSpec.describe :unescape_html do
  link :unescape_html, from: :ree_text

  it {
    expect(unescape_html("&lt;h1&gt;Hello&lt;/h1&gt;")).to eq("<h1>Hello</h1>")
  }
end