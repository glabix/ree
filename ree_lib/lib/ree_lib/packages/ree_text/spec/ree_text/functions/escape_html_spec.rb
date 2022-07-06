# frozen_string_literal: true

RSpec.describe :escape_html do
  link :escape_html, from: :ree_text
  link :to_json, from: :ree_json
  
  it {
    obj = {
      id: 1
    }

    result = escape_html(to_json(obj))
    expect(result).to eq("{&quot;id&quot;:1}")
  }

  it {
    expect(escape_html("<h1>Hello</h1>")).to eq("&lt;h1&gt;Hello&lt;/h1&gt;")
  }
end