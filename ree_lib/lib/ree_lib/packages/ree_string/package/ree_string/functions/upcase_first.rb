# frozen_string_literal: true

class ReeString::UpcaseFirst
  include Ree::FnDSL

  fn :upcase_first

  doc(<<~DOC)
    Converts just the first character to uppercase.
    
      upcase_first('what a Lovely Day') # => "What a Lovely Day"
      upcase_first('w')                 # => "W"
      upcase_first('')                  # => ""
  DOC
  contract(String => String)
  def call(string)
    string.length > 0 ? string[0].upcase.concat(string[1..-1]) : ""
  end
end