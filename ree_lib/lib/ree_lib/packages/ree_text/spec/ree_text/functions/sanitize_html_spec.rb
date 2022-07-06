# frozen_string_literal: true

RSpec.describe :sanitize_html do
  link :sanitize_html, from: :ree_text

  context "nested tags" do
    it {
      expect(sanitize_html(
        '<script><script></script>alert("XSS");<script><</script>/</script><script>script></script>', 
        tags: %w(em)
        )
      ).to eq('&lt;script&gt;alert("XSS");&lt;/script&gt;')

      expect(sanitize_html(
        '<style><script></style>alert("XSS");<style><</style>/</style><style>script></style>', 
        tags: %w(em)
        )
      ).to eq('&lt;script&gt;alert("XSS");&lt;/script&gt;')      
    }
  end

  context "uri escaping" do
    it {
      expect(sanitize_html(%{<a href='examp<!--" unsafeattr=foo()>-->le.com'>test</a>}))
        .to eq(%{<a href="examp&lt;!--%22%20unsafeattr=foo()&gt;--&gt;le.com">test</a>})

      expect(sanitize_html(%{<a src='examp<!--" unsafeattr=foo()>-->le.com'>test</a>}))
        .to eq(%{<a src="examp&lt;!--%22%20unsafeattr=foo()&gt;--&gt;le.com">test</a>})

      expect(sanitize_html(%{<a name='examp<!--" unsafeattr=foo()>-->le.com'>test</a>}))
        .to eq(%{<a name="examp&lt;!--%22%20unsafeattr=foo()&gt;--&gt;le.com">test</a>})
      
      expect(sanitize_html(
        %{<a action='examp<!--" unsafeattr=foo()>-->le.com'>test</a>},
        attributes: ['action']
        )
      ).to eq(%{<a action="examp&lt;!--%22%20unsafeattr=foo()&gt;--&gt;le.com">test</a>})
    }
  end

  context "exclude node" do
    it {
      expect(sanitize_html("<div>text</div><?div content><b>text</b>")).to eq("<div>text</div><b>text</b>")
      expect(sanitize_html("<div>text</div><!-- comment --><b>text</b>")).to eq("<div>text</div><b>text</b>")
    }
  end

  context "general" do
    it {
      expect(sanitize_html("<u>foo</u>", tags: %w(u))).to eq("<u>foo</u>")
      expect(sanitize_html("<u>foo</u> with <i>bar</i>", tags: %w(u))).to eq("<u>foo</u> with bar")
      expect(sanitize_html(%(<blockquote cite="http://example.com/">foo</blockquote>))).to eq(%(<blockquote cite="http://example.com/">foo</blockquote>))
      expect(sanitize_html(%(<a data-foo="foo">foo</a>), attributes: ['data-foo'])).to eq(%(<a data-foo="foo">foo</a>))
      expect(sanitize_html("<form action=\"/foo/bar\" method=\"post\"><input></form>")).to eq("")
      expect(sanitize_html('<a foo="hello" bar="world"></a>', attributes: %w(foo))).to eq('<a foo="hello"></a>')
      expect(sanitize_html('<a><u></u></a>', tags: %w(u))).to eq('<u></u>')
      expect(sanitize_html('<a><u></u></a>', tags: %w(a))).to eq('<a></a>')
      expect(sanitize_html("<u>foo</u>", tags: %w(u))).to eq("<u>foo</u>")
      expect(sanitize_html('<a foo="hello" bar="world"></a>', attributes: %w(bar))).to eq('<a bar="world"></a>')
      expect(sanitize_html("<u>foo</u> with <i>bar</i>", tags: %w(u))).to eq("<u>foo</u> with bar")
      expect(sanitize_html('<u>leave me <b>now</b></u>', prune: true, tags: %w(u))).to eq("<u>leave me </u>")

      expect(
        sanitize_html(
          %(<blockquote foo="bar">Lorem ipsum</blockquote>), 
          attributes: ['foo']
        )
      ).to eq(%(<blockquote foo="bar">Lorem ipsum</blockquote>))

      expect(
        sanitize_html(
          '<p style="color: #000; background-image: url(http://www.ragingplatypus.com/i/cam-full.jpg);"></p>',
          attributes: %w(style)
        )
      ).to eq('<p style="color:#000;"></p>')
    }    
  end
end