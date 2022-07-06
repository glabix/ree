# frozen_string_literal: true

RSpec.describe :simple_format do
  link :simple_format, from: :ree_text

  context "general" do
    it {
      expect(simple_format("")).to eq("<p></p>")
      expect(simple_format("ridiculous\r\n cross\r platform linebreaks")).to eq("<p>ridiculous\n<br /> cross\n<br /> platform linebreaks</p>")
      expect(simple_format("A paragraph\n\nand another one!")).to eq("<p>A paragraph</p>\n\n<p>and another one!</p>")
      expect(simple_format("A paragraph\n With a newline")).to eq("<p>A paragraph\n<br /> With a newline</p>")
      expect(simple_format("A\nB\nC\nD")).to eq("<p>A\n<br />B\n<br />C\n<br />D</p>")
      expect(simple_format("A\r\n  \nB\n\n\r\n\t\nC\nD")).to eq("<p>A\n<br />  \n<br />B</p>\n\n<p>\t\n<br />C\n<br />D</p>")
    }    
  end

  context "options" do
    it {
      expect(simple_format("This is a classy test", html_options: {class: "test"})).to eq('<p class="test">This is a classy test</p>')
      expect(simple_format("This is a classy test", html_options: {class: "test", data: "id"})).to eq('<p class="test" data="id">This is a classy test</p>')
      expect(simple_format("para 1\n\npara 2", html_options: { class: "test" })).to eq(%Q(<p class="test">para 1</p>\n\n<p class="test">para 2</p>))
      expect(simple_format("<blink>Unblinkable.</blink>", sanitize: true)).to eq("<p>Unblinkable.</p>")
      expect(simple_format("<b> test with unsafe string </b><script>code!</script>", sanitize: true )).to eq("<p><b> test with unsafe string </b>code!</p>")
      expect(simple_format("<b> test with unsafe string </b><script>code!</script>", sanitize: false)).to eq("<p><b> test with unsafe string </b><script>code!</script></p>")
      expect(simple_format("", wrapper_tag: "div")).to eq("<div></div>")
      expect(simple_format("We want to put a wrapper...\n\n...right there.", wrapper_tag: "div")).to eq("<div>We want to put a wrapper...</div>\n\n<div>...right there.</div>")
    }
  end
end