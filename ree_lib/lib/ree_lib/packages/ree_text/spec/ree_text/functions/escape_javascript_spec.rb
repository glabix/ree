# frozen_string_literal: true

RSpec.describe :escape_javascript do
  link :escape_javascript, from: :ree_text

  context "general" do
    it {
      expect(escape_javascript("`")).to eq("\\`")
      expect(escape_javascript("$")).to eq("\\$")
      expect(escape_javascript(nil)).to eq("")
      expect(escape_javascript(123)).to eq("123")
      expect(escape_javascript(:en)).to eq("en")
      expect(escape_javascript(false)).to eq("false")
      expect(escape_javascript(true)).to eq("true")
      expect(escape_javascript(%(This "thing" is really\n netos'))).to eq(%(This \\"thing\\" is really\\n netos\\'))
      expect(escape_javascript(%(backslash\\test))).to eq(%(backslash\\\\test))
      expect(escape_javascript(%(don't </close> tags))).to eq(%(don\\'t <\\/close> tags))
      expect(escape_javascript(%('quoted' "double-quoted" new-line:\n </closed>))).to eq(%(\\'quoted\\' \\"double-quoted\\" new-line:\\n <\\/closed>))
      # assert_equal %(unicode &#x2028; newline), escape_javascript((+%(unicode \342\200\250 newline)).force_encoding(Encoding::UTF_8).encode!)
      # assert_equal %(unicode &#x2029; newline), escape_javascript((+%(unicode \342\200\251 newline)).force_encoding(Encoding::UTF_8).encode!)
    }    
  end
end