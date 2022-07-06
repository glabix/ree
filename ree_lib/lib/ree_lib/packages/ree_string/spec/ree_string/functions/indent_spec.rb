# frozen_string_literal: true

RSpec.describe :indent do
  link :indent, from: :ree_string

  it {
    expect(indent("  foo", 2)).to eq("    foo")
    expect(indent("foo\n\t\tbar", 2)).to eq("\t\tfoo\n\t\t\t\tbar")
    expect(indent("foo", 2, indent_string: "\t")).to eq("\t\tfoo")
    expect(indent("foo\n\nbar", 2, empty_lines: true)).to eq("  foo\n  \n  bar")

    string = "\t\tdef some_method(x, y)\n\t\t\t\tsome_code\n\t\tend"
    result = "....\t\tdef some_method(x, y)\n....\t\t\t\tsome_code\n....\t\tend"

    expect(indent(string, 4, indent_string: ".")).to eq(result)
  }
end