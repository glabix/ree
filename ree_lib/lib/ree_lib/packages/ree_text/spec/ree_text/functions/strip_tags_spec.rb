# frozen_string_literal: true

RSpec.describe :strip_tags do
  link :strip_tags, from: :ree_text

  context "general" do
    it {
      expect(strip_tags('<" <img src="trollface.gif" onload="alert(1)"> hi')).to eq(%{&lt;"  hi})
      expect(strip_tags("Wei<<a>a onclick='alert(document.cookie);'</a>/>rdos")).to eq("Wei&lt;a onclick='alert(document.cookie);'/&gt;rdos")
      expect(strip_tags("<<<bad html>")).to eq( "&lt;&lt;")
      expect(strip_tags("This is <-- not\n a comment here.")).to eq(%{This is &lt;-- not\n a comment here.})
      expect(strip_tags("This has a <![CDATA[<section>]]> here.")).to eq(%{This has a &lt;![CDATA[]]&gt; here.})
      expect(strip_tags("This has an unclosed <![CDATA[<section>]] here...")).to eq(%{This has an unclosed &lt;![CDATA[]] here...})
      expect(strip_tags("")).to eq("")
      expect(strip_tags("   ")).to eq("   ")
      expect(strip_tags("Don't touch me")).to eq("Don't touch me")
      expect(strip_tags("<<<bad html>")).to eq( "&lt;&lt;")
      expect(strip_tags("This is a test.")).to eq("This is a test.")
      expect(strip_tags("This has a <!-- comment --> here.")).to eq("This has a  here.")
      expect(strip_tags("Frozen string with no tags".freeze)).to eq("Frozen string with no tags")
      expect(strip_tags("<scpript")).to eq("")
      expect(strip_tags("Jekyll & Hyde")).to eq("Jekyll &amp; Hyde")

      expect(strip_tags(%{<title>This is <b>a <a href="" target="_blank">test</a></b>.</title>\n\n<!-- it has a comment -->\n\n<p>It no <b>longer <strong>contains <em>any <strike>HTML</strike></em>.</strong></b></p>\n}))
        .to eq(%{This is a test.\n\n\n\nIt no longer contains any HTML.\n})
    }
  end

  context "html escaping of the given string" do
    it {
      expect(strip_tags("test\r\nstring")).to eq("test\r\nstring")
      expect(strip_tags("&")).to eq("&amp;")
      expect(strip_tags("&amp;")).to eq("&amp;")
      expect(strip_tags("&amp;&amp;")).to eq("&amp;&amp;")
      expect(strip_tags("omg &lt;script&gt;BOM&lt;/script&gt;")).to eq("omg &lt;script&gt;BOM&lt;/script&gt;")
    }
  end
end