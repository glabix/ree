# frozen_string_literal: true

RSpec.describe :strip_links do
  link :strip_links, from: :ree_text

  it {
    expect(strip_links("<<a>a href='hello'>all <b>day</b> long<</A>/a>")).to eq("&lt;a href='hello'&gt;all <b>day</b> long&lt;/a&gt;")
    expect(strip_links("<a<a")).to eq("")
    expect(strip_links("Don't touch me")).to eq("Don't touch me")
    expect(strip_links("<a href='almost'>My mind</a>\n<A href='almost'>all <b>day</b> long</A>")).to eq("My mind\nall <b>day</b> long")

    expect(strip_links("<a href='almost'>on my mind</a>\n<A href='almost'>all day long</A>"))
      .to eq("on my mind\nall day long")

    expect(strip_links("<a href='http://www.example.com/'><a href='http://www.ruby-lang.org/' onlclick='steal()'>0wn3d</a></a>"))
      .to eq("0wn3d")
    
    expect(strip_links("<a href='http://www.example.com/'>Mag<a href='http://www.ruby-lang.org/'>ic"))
      .to eq("Magic")
  }
end