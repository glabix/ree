# frozen_string_literal: true

class ReeString::Remove
  include Ree::FnDSL

  fn :remove

  doc(<<~DOC)
    Alters the string by removing all occurrences of the patterns.
      remove("foo bar test", [" test", /bar/])         # => "foo "
  DOC
  contract(String, ArrayOf[Or[String, Regexp]] => String)
  def call(str, patterns)
    str = str.dup

    patterns.each do |pattern|
      str.gsub!(pattern, "")
    end

    str
  end
end