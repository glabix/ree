# frozen_string_literal: true

class ReeString::Squish
  include Ree::FnDSL

  fn :squish

  doc(<<~DOC)
    Returns the string, first removing all whitespace on both ends of
    the string, and then changing remaining consecutive whitespace
    groups into one space each.
    
    Note that it handles both ASCII and Unicode whitespace.
    
      squish(%{ Multi-line
         string })                          # => "Multi-line string"
      squish(" foo   bar    \n   \t   boo") # => "foo bar boo"
  DOC
  contract(String => String)
  def call(str)
    str
      .dup
      .gsub!(/[[:space:]]+/, " ")
      .strip!
  end
end