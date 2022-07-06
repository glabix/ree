# frozen_string_literal: true

RSpec.describe :highlight do
  link :highlight, from: :ree_text

  context "general" do
    it {
      expect(highlight("")).to eq("")
      expect(highlight("This is a beautiful morning", "beautiful")).to eq("This is a <mark>beautiful</mark> morning")
      expect(highlight("This is a beautiful morning, but also a beautiful day", "beautiful")).to eq("This is a <mark>beautiful</mark> morning, but also a <mark>beautiful</mark> day")
      expect(highlight("This is a beautiful morning, but also a beautiful day", "beautiful", highlighter: '<b>\1</b>')).to eq("This is a <b>beautiful</b> morning, but also a <b>beautiful</b> day")
      expect(highlight("This text is not changed because we supplied an empty phrase")).to eq("This text is not changed because we supplied an empty phrase")
      expect(highlight("   ", "blank text is returned verbatim")).to eq("   ")
      expect(highlight("This is a beautiful morning<script>code!</script>", "beautiful")).to eq("This is a <mark>beautiful</mark> morningcode!")
      expect(highlight("This is a beautiful morning<script>code!</script>", "beautiful", sanitize: false)).to eq("This is a <mark>beautiful</mark> morning<script>code!</script>")
      expect(highlight("This is a beautiful! morning", "beautiful!")).to eq("This is a <mark>beautiful!</mark> morning")
      expect(highlight("This is a beautiful! morning", "beautiful! morning")).to eq("This is a <mark>beautiful! morning</mark>")
      expect(highlight("This is a beautiful? morning", "beautiful? morning")).to eq("This is a <mark>beautiful? morning</mark>")    
      expect(highlight("This day was challenging for judge Allen and his colleagues.", /\ballen\b/i)).to eq("This day was challenging for judge <mark>Allen</mark> and his colleagues.")
      expect(highlight("wow em", %w(wow em), highlighter: '<em>\1</em>')).to eq(%(<em>wow</em> <em>em</em>))
      expect(highlight("one two three", ["one", "two", "three"]) { |word| "<b>#{word}</b>" }).to eq("<b>one</b> <b>two</b> <b>three</b>")
    }
  end

  context "highlight with html" do
    it {
      expect(highlight("<p>This is a beautiful morning, but also a beautiful day</p>", "beautiful"))
        .to eq("<p>This is a <mark>beautiful</mark> morning, but also a <mark>beautiful</mark> day</p>")
      expect(highlight("<p>This is a <em>beautiful</em> morning, but also a beautiful day</p>", "beautiful"))
        .to eq("<p>This is a <em><mark>beautiful</mark></em> morning, but also a <mark>beautiful</mark> day</p>")
      expect(highlight("<p>This is a <em class=\"error\">beautiful</em> morning, but also a beautiful <span class=\"last\">day</span></p>", "beautiful"))
        .to eq("<p>This is a <em class=\"error\"><mark>beautiful</mark></em> morning, but also a <mark>beautiful</mark> <span class=\"last\">day</span></p>")
      expect(highlight("<p class=\"beautiful\">This is a beautiful morning, but also a beautiful day</p>", "beautiful"))
        .to eq("<p class=\"beautiful\">This is a <mark>beautiful</mark> morning, but also a <mark>beautiful</mark> day</p>")
      expect(highlight("<p>This is a beautiful <a href=\"http://example.com/beautiful\#top?what=beautiful%20morning&when=now+then\">morning</a>, but also a beautiful day</p>", "beautiful"))
        .to eq("<p>This is a <mark>beautiful</mark> <a href=\"http://example.com/beautiful#top?what=beautiful%20morning&amp;when=now+then\">morning</a>, but also a <mark>beautiful</mark> day</p>")
      expect(highlight("<div>abc div</div>", "div", highlighter: '<b>\1</b>')).to eq("<div>abc <b>div</b></div>")
    }
  end
end