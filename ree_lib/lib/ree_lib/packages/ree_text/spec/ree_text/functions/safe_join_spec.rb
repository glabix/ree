# frozen_string_literal: true

RSpec.describe :safe_join do
  link :safe_join, from: :ree_text

  it {
    expect(safe_join(["<p>foo</p>", "<p>bar</p>"], sep: "<br />")).to eq("&lt;p&gt;foo&lt;/p&gt;&lt;br /&gt;&lt;p&gt;bar&lt;/p&gt;")
    expect(safe_join(["a", ["b", "c"]], sep: ":")).to eq("a:b:c")
    expect(safe_join(['"a"', ["<b>", "<c>"]], sep: " <br/> ")).to eq("&quot;a&quot; &lt;br/&gt; &lt;b&gt; &lt;br/&gt; &lt;c&gt;")
    expect(safe_join(["a", "b"])).to eq("a$b")
    expect(safe_join(["a", "b"], sep: "|")).to eq("a|b")
  }
end