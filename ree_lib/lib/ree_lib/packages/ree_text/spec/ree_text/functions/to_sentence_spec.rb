# frozen_string_literal: true

RSpec.describe :to_sentence do
  link :to_sentence, from: :ree_text

  it {
    expect(to_sentence(%w(< > & ' "))).to eq("&amp;lt;, &amp;gt;, &amp;amp;, &amp;#39;, and &quot;")
    expect(to_sentence(%w(<script>))).to eq("&lt;script&gt;")
    expect(to_sentence(["one", "two", "three"], last_word_connector: " <script>alert(1)</script> ")).to eq("one, two &lt;script&gt;alert(1)&lt;/script&gt; three")
    expect(to_sentence(["one", "two"], two_words_connector: " & ")).to eq("one &amp; two")
    expect(to_sentence(["one", "two", "three"], words_connector: " & ")).to eq("one &amp;amp; two, and three")
    expect(to_sentence(["", "two", "three"])).to eq(", two, and three")
    expect(to_sentence(["one", "two", "three"], words_connector: " ")).to eq("one two, and three")
    expect(to_sentence(["one", "two", "three"], words_connector: "")).to eq("onetwo, and three")
    expect(to_sentence(["one", "two", "three"], last_word_connector: ", and also ")).to eq("one, two, and also three")
    expect(to_sentence(["one", "two", "three"], last_word_connector: "")).to eq("one, twothree")
    expect(to_sentence(["one", "two", "three"], last_word_connector: " ")).to eq("one, two three")
    expect(to_sentence(["one", "two", "three"], last_word_connector: " and ")).to eq("one, two and three")
  }

      # expect(to_sentence(["&lt;script&gt;"])).to eq("&amp;lt;script&amp;gt;")
end