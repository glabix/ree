# frozen_string_literal: true

RSpec.describe :sanitize_css do
  link :sanitize_css, from: :ree_text

  it {
    str = %(display:block; position:absolute; left:0; top:0; width:100%; height:100%; z-index:1; background-color:black; background-image:url(http://www.ragingplatypus.com/i/cam-full.jpg); background-x:center; background-y:center; background-repeat:repeat;)
    result = %r(\Adisplay:\s?block;\s?width:\s?100%;\s?height:\s?100%;\s?background-color:\s?black;\s?background-x:\s?center;\s?background-y:\s?center;\z)
    expect(sanitize_css(str)).to match(result)
  }
end